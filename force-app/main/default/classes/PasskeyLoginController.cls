public with sharing class PasskeyLoginController {
    @AuraEnabled
    public static String generateChallenge() {
        return PasskeyService.generateChallenge();
    }

    @AuraEnabled
    public static String loginWithPasskey(String authInfo) {
        PasskeyService.AuthenticationInfo passkeyInfo = (PasskeyService.AuthenticationInfo) JSON.deserialize(authInfo, PasskeyService.AuthenticationInfo.class);
        return PasskeyService.loginWithPasskey(passkeyInfo);
    }

    @AuraEnabled(cacheable=true)
    public static PasskeyService.ExperienceInfo getExperienceInfo(){
        return PasskeyService.getExperienceInfo();
    }
}