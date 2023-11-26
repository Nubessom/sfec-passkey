public with sharing class PasskeyRegistrationController {
    
    @AuraEnabled
    public static String generateChallenge() {
        return PasskeyService.generateChallenge();
    }

    @AuraEnabled
    public static Boolean registerPasskey(String registrationInfo){
        PasskeyService.RegistrationInfo passkeyInfo = (PasskeyService.RegistrationInfo) JSON.deserialize(registrationInfo, PasskeyService.RegistrationInfo.class);
        return PasskeyService.registerPasskey(passkeyInfo);
    }

    @AuraEnabled(cacheable=true)
    public static PasskeyService.ExperienceInfo getExperienceInfo(){
        return PasskeyService.getExperienceInfo();
    }
}