# Passkey Implementation for Salesforce Experience Cloud (Community Cloud)

**IMPORTANT:** This code is intended for educational and demonstrative purposes only. It should not be used in a production instance without thorough testing and security analysis.

## Deploy Code to Your Scratch Org / Sandbox

<a href="https://githubsfdeploy-sandbox.herokuapp.com/app/githubdeploy/Nubessom/sfec-passkey">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Update reCAPTCHA Keys

1. Update site Head Markdown to include your SITE KEY
2. Update Recaptcha class to include your SERVER Key

## Update Authentication Information

1. Generate new Certificate in Setup -> Security -> Certificate and Key Management and give it "Passkey_Authentication" as unique Name
2. Download generated Certificate and update it in "Passkey Authentication" Connected App found in Setup -> Apps -> App Manager
3. Update YOUR-CLIENT-ID in PasskeyService class with Consumer Key from Connected App
4. Update Remote Site Settings "Default_Token_Endpoint" to your Experience Cloud domain
5. Give access to Connected App to users that you would want to allow Passkey Athentication

## Publish Community

Don't forget to publish FIDO Passkey site before testing!