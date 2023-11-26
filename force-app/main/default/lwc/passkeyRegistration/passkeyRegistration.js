import { LightningElement, wire } from 'lwc';
import userId from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import getChallenge from "@salesforce/apex/PasskeyRegistrationController.generateChallenge";
import register from "@salesforce/apex/PasskeyRegistrationController.registerPasskey";
import getExperienceInfo from "@salesforce/apex/PasskeyRegistrationController.getExperienceInfo";
import { checkPasskeyAvailability, string2ArrayBuffer, arrayBuffer2Base64Url, arrayBuffer2Base64 } from "c/passkeyUtils";

const FIELDS = ["User.Name", "User.Email"];


export default class passkeyRegistration extends LightningElement {

    passkeyAvailable = false;
    showRegistrationSuccess = false;

    get passkeyDisabled() {
        return !this.passkeyAvailable;
    }

    @wire(getRecord, { recordId: userId, fields: FIELDS })
    user;

    @wire(getExperienceInfo)
    experienceInfo;

    connectedCallback() {
        //Check if passkey features are availabin in this browser
        this.passkeyAvailable = checkPasskeyAvailability();
    }

    handlePasskeyRegistration() {
        getChallenge().then(challenge => {
            let publicKeyCredentialCreationOptions = {
                challenge: string2ArrayBuffer(challenge),
                rp: {
                    id: this.experienceInfo.data.host,
                    name: this.experienceInfo.data.name
                },
                user: {
                    id: string2ArrayBuffer(userId),
                    name: this.user.data.fields.Email.value,
                    displayName: this.user.data.fields.Name.value,
                },
                pubKeyCredParams: [
                    { alg: -7, type: "public-key" }, // "ES256" as registered in the IANA COSE Algorithms registry
                    { alg: -257, type: "public-key" }, // Value registered by this specification for "RS256"
                ],
                /*
                Prevents registering the same device by providing a list of already registered credential IDs. 
                The transports member, if provided, should contain the result of calling getTransports() during the registration of each credential.
                excludeCredentials: [{  
                  id: *****,  
                  type: 'public-key',  
                  transports: ['internal'],  
                }],  
                */
                authenticatorSelection: {
                    authenticatorAttachment: "platform",
                    residentKey: "required",
                    requireResidentKey: "true",
                    userVerification: "required",
                },
            };

            navigator.credentials.create({  
                publicKey: publicKeyCredentialCreationOptions  
            }).then(credential => {

                let registrationInfo = {
                    credentialId: credential.id,
                    rawId: arrayBuffer2Base64Url(credential.rawId),
                    type: credential.type,
                    publicKey: arrayBuffer2Base64(credential.response.getPublicKey()),
                    publicKeyAlgorithm: credential.response.getPublicKeyAlgorithm(),
                    clientDataJSON: new TextDecoder().decode(credential.response.clientDataJSON)
                };
                
                register({ 
                    registrationInfo: JSON.stringify(registrationInfo)
                }).then(result => {
                    if(result) {
                        this.passkeyAvailable = false;
                        this.showRegistrationSuccess = true;
                    }
                });
                
            }).catch(function (err) {
                console.log(err);
                // No acceptable auth device or user refused consent. Handle appropriately.
            });
        });
    }
}