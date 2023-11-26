public with sharing class Recaptcha {
    private static final String ENDPOINT = 'https://www.google.com/recaptcha/api/siteverify';
    private static final String SECRET = 'YOUR-SECRET-KEY';

    public static Boolean verify(String token) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT);
        request.setMethod('POST');
        request.setBody('secret=' + SECRET + '&response=' + token);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            RecaptchaResponse resp = (RecaptchaResponse) JSON.deserialize(response.getBody(), RecaptchaResponse.class);
            return resp.success;
        }

        return false;
    }

    public with sharing class RecaptchaResponse {
        public Boolean success;
        public Datetime challenge_ts;
        public String hostname;
    }
}