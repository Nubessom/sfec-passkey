public without sharing class PasskeyService {

    private static final String CLIENT_ID = 'YOUR-CLIENT-ID'; 
    private static final String CERT = 'Passkey_Authentication'; // unique name name of certificate 
    private static final Integer VALIDITY = 3600; // in seconds 
    private static final String CHALLENGE_KEY = 'local.passkey.challenge';

    private static final Map<String, String> ALGORITHMS = new Map<String, String>{
        '-7' => 'ECDSA-SHA256',
        '-256' => 'HmacSHA256'
    };
    
    public static String generateChallenge() {
        String challenge = Utils.getRandomString(32);
        Cache.Session.put(CHALLENGE_KEY, challenge);
        return challenge;
    }

    public static ExperienceInfo getExperienceInfo() {
        return new ExperienceInfo(Site.getMasterLabel(), Utils.COMMUNITY_URL.getHost());
    }

    public static Boolean registerPasskey(RegistrationInfo regInfo) {
        try {
            //Validate basic information

            // Ensure ID is base64url-encoded
            if (regInfo.credentialId != regInfo.rawId || regInfo.credentialId == null) {
                throw new PasskeyRegistrationException('Credential ID was not base64url-encoded');
            }

            // Make sure credential type is public-key
            if (regInfo.type != 'public-key') {
                throw new PasskeyRegistrationException('Unexpected credential type ${credentialType}, expected "public-key"');
            }

            ClientData cData = (ClientData) JSON.deserialize(regInfo.clientDataJSON, ClientData.class);

            if(cData.type != 'webauthn.create') {
                throw new PasskeyRegistrationException('Unexpected registration response type: ' + cData.type);
            }

            String algorithm = ALGORITHMS.get(regInfo.publicKeyAlgorithm);
            if(algorithm == null) {
                throw new PasskeyRegistrationException('Unexpected public key algoritn: ' + regInfo.publicKeyAlgorithm);
            }

            if(String.isBlank(regInfo.publicKey)) {
                throw new PasskeyRegistrationException('No Public Key found');
            }

            // Ensure the device provided the challenge we gave it
            String expectedChallenge = (String) Cache.Session.get('local.passkey.challenge');
            if (cData.challenge == null || Utils.base64UrlDecode(cData.challenge) != expectedChallenge) {
                throw new PasskeyRegistrationException(
                    'Unexpected registration response challenge "' + cData.challenge + '", expected "' + expectedChallenge + '"'
                );
            }

            // Check that the origin is our site
            URL originUrl = new URL(Site.getBaseSecureUrl());
            String expectedOrigin = originUrl.getProtocol() + '://' + originUrl.getHost();
            if(cData.origin != expectedOrigin) {
                throw new PasskeyRegistrationException(
                    'Unexpected registration response origin "' + cData.origin + '", expected "' + expectedOrigin +'"'
                );
            }

            Blob publicKeyBlob = EncodingUtil.base64Decode(regInfo.publicKey);

            insert as system new User_Credential__c(User__c = UserInfo.getUserId(),
                                                    Credential_Id__c = regInfo.credentialId,
                                                    Public_Key__c = regInfo.publicKey,
                                                    Public_Key_Algorithm__c = algorithm);

            //Remove challenge from cache
            Cache.Session.remove(CHALLENGE_KEY);

            return true;
        } catch (Exception ex) {
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            throw new AuraHandledException('Failed to register Passkey');
        }
    }

    public static String loginWithPasskey(AuthenticationInfo authInfo) {
        try {
            
            ClientData cData = (ClientData) JSON.deserialize(authInfo.clientDataJSON, ClientData.class);

            if(cData.type != 'webauthn.get') {
                throw new PasskeyVerificationException('Unexpected verification response type: ' + cData.type);
            }

            //Validating challenge
            if(cData.challenge != null && Recaptcha.verify(cData.challenge)) {
                throw new PasskeyVerificationException('Invalid challenge');
            }

            User_Credential__c credential = [SELECT User__r.Username, Public_Key__c, Public_Key_Algorithm__c
                                             FROM User_Credential__c 
                                             WHERE User__c = :authInfo.userId AND Credential_Id__c = :authInfo.credentialId
                                             WITH SYSTEM_MODE 
                                             LIMIT 1];

            //signature structure: https://w3c.github.io/webauthn/#fig-signature
            String hexAuthenticatorData = EncodingUtil.convertToHex(EncodingUtil.base64Decode(authInfo.authenticatorData));
            String hexClientData = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(authInfo.clientDataJSON)));
            Blob data = EncodingUtil.convertFromHex(hexAuthenticatorData + hexClientData);

            Boolean verified = Crypto.verify(credential.Public_Key_Algorithm__c, 
                                            data, 
                                            EncodingUtil.base64Decode(authInfo.signature), 
                                            EncodingUtil.base64Decode(credential.Public_Key__c));

            if(verified) {
                String accessToken = getUserAccessToken(credential.User__r.Username);
                String startUrl = String.isBlank(authInfo.startUrl) ? '/' : authInfo.startUrl;

                //Pass access token to frontdoor to create a web session 
                return Utils.COMMUNITY_VF_URL + '/secur/frontdoor.jsp?sid=' + accessToken + '&retURL=' + startUrl; 
            } else {
                throw new PasskeyVerificationException('Invalid signature / credential details');
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            throw new AuraHandledException('Failed to authenticate with Passkey');
        }
    }

    private static String getUserAccessToken(String username) { 
        

        //Generate JWT Token
        Auth.JWT jwt = new Auth.JWT(); 
        jwt.setSub(username); 
        jwt.setAud(Utils.COMMUNITY_VF_URL);
        jwt.setIss(CLIENT_ID); 
        jwt.setValidityLength(VALIDITY); 
        Auth.JWS jws = new Auth.JWS(jwt.toJSONString(), CERT); 

        //Post the JWT to token endpoint
        String endpoint = Utils.COMMUNITY_VF_URL + '/services/oauth2/token';
        Auth.JWTBearerTokenExchange tokenExchange = new Auth.JWTBearerTokenExchange(endpoint, jws);
        String accessToken = tokenExchange.getAccessToken();

        //Throw an Exception is access token is was not retrieved
        if(String.isBlank(accessToken)){
            throw new PasskeyTokenException('Failed to retrieve access token');
        }
        
        return accessToken;
    }

    public with sharing class RegistrationInfo {
        @AuraEnabled
        public String credentialId;
        @AuraEnabled
        public String rawId;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String publicKey;
        @AuraEnabled
        public String publicKeyAlgorithm;
        @AuraEnabled
        public String clientDataJSON;
    }

    public with sharing class AuthenticationInfo {
        @AuraEnabled
        public String userId;
        @AuraEnabled
        public String credentialId;
        @AuraEnabled
        public String authenticatorData;
        @AuraEnabled
        public String clientDataJSON;
        @AuraEnabled
        public String startUrl;
        @AuraEnabled
        public String signature;
    }

    public with sharing class ClientData {
        public String type;
        public String challenge;
        public String origin;
        public String crossOrigin;
    }

    public with sharing class ExperienceInfo {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String host;

        public ExperienceInfo(String name, String host) {
            this.name = name;
            this.host = host;
        }
    }

    public with sharing class PasskeyRegistrationException extends Exception {}
    public with sharing class PasskeyTokenException extends Exception {}
    public with sharing class PasskeyVerificationException extends Exception {}
}