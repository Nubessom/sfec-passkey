import { LightningElement, wire } from 'lwc';
import loginWithPasskey from "@salesforce/apex/PasskeyLoginController.loginWithPasskey";
import getExperienceInfo from "@salesforce/apex/PasskeyLoginController.getExperienceInfo";
import { CurrentPageReference } from "lightning/navigation";
import { checkPasskeyAvailability, string2ArrayBuffer, arrayBuffer2Base64, arrayBuffer2String } from "c/passkeyUtils";

export default class passkeyLogin extends LightningElement {
    
    passkeyAvailable = false;

    get passkeyDisabled() {
        return !this.passkeyAvailable;
    }

    @wire(CurrentPageReference)
    currentPageReference;

    @wire(getExperienceInfo)
    experienceInfo;

    connectedCallback() {
        //Check if passkey features are availabin in this browser
        this.passkeyAvailable = checkPasskeyAvailability();
        this.addRecaptchaVerificationHandler();
    }

    handleLogin() {
        document.dispatchEvent(new CustomEvent("grecaptchaExecute", {"detail": {action: "passkeyLogin"}}));
    }

    addRecaptchaVerificationHandler() {
        let that = this;

        document.addEventListener("grecaptchaVerified", function(e) {
            if (e.detail.action !== 'passkeyLogin') {
                return;
            }

            let challenge = e.detail.response;

            var options = {
                // The challenge is produced by Google reCAPTCHA
                challenge: string2ArrayBuffer(challenge),
                timeout: 300000,  // 5 minutes
                allowCredentials: [],
                userVerification: "required",
                rpId: that.experienceInfo.host
            };

            navigator.credentials.get({ "publicKey": options })
                .then(function (assertion) {
                    let authInfo = {
                        userId: arrayBuffer2String(assertion.response.userHandle),
                        credentialId: assertion.id,
                        signature: arrayBuffer2Base64(assertion.response.signature),
                        authenticatorData: arrayBuffer2Base64(assertion.response.authenticatorData), 
                        clientDataJSON: new TextDecoder().decode(assertion.response.clientDataJSON),
                        startUrl: that.currentPageReference.state['startURL']
                    };

                    loginWithPasskey({ authInfo: JSON.stringify(authInfo) }).then(result => {
                        window.open(result, "_self");
                    }).catch(err => {
                        console.log(err)
                    });
                }).catch(function (err) {
                    console.log(err);
                    // No acceptable credential or user refused consent. Handle appropriately.
                });
        });
    }
}