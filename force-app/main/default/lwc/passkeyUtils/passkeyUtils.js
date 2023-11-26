const arrayBuffer2String = (buffer) => {
    return String.fromCharCode.apply(null, new Uint8Array(buffer));
}

const string2ArrayBuffer = (str) => {
    var buf = new ArrayBuffer(str.length);
    var bufView = new Uint8Array(buf);
    for (var i=0, strLen = str.length; i < strLen; i++) {
        bufView[i] = str.charCodeAt(i);
    }
    return buf;
}

const arrayBuffer2Base64 = (buffer) => {
    return btoa(arrayBuffer2String(buffer));
}

const arrayBuffer2Base64Url = (buffer) => {
    return arrayBuffer2Base64(buffer).replace(/\+/g, '-')
                                     .replace(/\//g, '_')
                                     .replace(/=+$/, '');
}

const checkPasskeyAvailability = () => {
    // Availability of `window.PublicKeyCredential` means WebAuthn is usable.  
    // `isUserVerifyingPlatformAuthenticatorAvailable` means the feature detection is usable.  
    // `​​isConditionalMediationAvailable` means the feature detection is usable.  
    console.log('Attempting to load window.PublicKeyCredential');
    if (window.PublicKeyCredential &&  
        window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable &&  
        window.PublicKeyCredential.isConditionalMediationAvailable) {  
            // Check if user verifying platform authenticator is available.  
            return Promise.all([  
                window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable(),  
                window.PublicKeyCredential.isConditionalMediationAvailable(),  
            ]).then(results => { 
                if (results.every(r => r === true)) {  
                    console.log('window.PublickKeyCredential is active');
                    return true;
                }
                return false;
            }).catch(error => {
                console.log('Failed to load window.PublicKeyCredential: ' + error);
                return false;
            });
    }  else {
        console.log('window.PublicKeyCredential is not available');
        return false;
    }
}


export { arrayBuffer2String, string2ArrayBuffer, arrayBuffer2Base64, arrayBuffer2Base64Url, checkPasskeyAvailability};