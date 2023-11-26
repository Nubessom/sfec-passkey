public with sharing class Utils {

    public static final URL COMMUNITY_URL {
        public get {
            if(COMMUNITY_URL == null) {
                if (!Test.isRunningTest()) {
                    COMMUNITY_URL = new URL(Site.getBaseSecureUrl());
                } else {
                    COMMUNITY_URL = new URL('https://fidopasskey-sample.my.salesforce-sites.com');
                }
            }
            return COMMUNITY_URL;
        }
        private set;
    }

    //Community URL for visualforce pages in LWR
    public static final String COMMUNITY_VF_URL {
        public get {
            if(COMMUNITY_VF_URL == null) {
                COMMUNITY_VF_URL = COMMUNITY_URL.toExternalForm();
                if(!COMMUNITY_URL.getPath()?.contains(Site.getPathPrefix())){
                    COMMUNITY_VF_URL =  + '/';
                }
                COMMUNITY_VF_URL += 'vforcesite';
            }
            return COMMUNITY_VF_URL;
        }
        private set;
    }

    private static final String CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    private static final Integer NUMBER_OF_POSSIBILITIES = CHARACTERS.length();
    public static String getRandomString(Integer length) {
        String result = '';
        for (Integer i = 0; i < length; i++) {
            Integer random = getRandomNumber(NUMBER_OF_POSSIBILITIES - 1);
            result += CHARACTERS.substring(random, random + 1);
        }
        return result;
    }

    public static Integer getRandomNumber(Integer maxValue) {
        Integer size = maxValue + 1;
        Double randomDouble = Math.random() * size;
        return randomDouble.intValue();
    }

    public static String base64UrlDecode(String str){
        if(String.isBlank(str)) {
            return null;
        }

        return EncodingUtil.base64Decode(str.replace('-', '+')
                                            .replace('_', '/')
                                            .rightPad(math.mod(str.length() + (math.mod(4 - str.length(), 4)), 4))
                                            .replace(' ','=')).toString();
    }
}