import { LightningElement, wire } from 'lwc';
import userId from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = ["User.Id", "User.Name", "User.Username", "User.Email", "User.SmallPhotoUrl", "User.FullPhotoUrl"];

export default class Profile extends LightningElement {
    
    @wire(getRecord, { recordId: userId, fields: FIELDS })
    user;

    get userId() {
        return userId;
    }

    get Username() {
        return (this.user?.data?.fields?.Username?.value) ? this.user.data.fields.Username?.value : 'Guest User';
    }

    get Email() {
        return (this.user?.data?.fields?.Email?.value) ? this.user.data.fields.Email?.value : 'No Email';
    }

    get Name() {
        return (this.user?.data?.fields?.Name?.value) ? this.user.data.fields.Name?.value : 'Guest';
    }

    get SmallPhotoUrl() {
        return this.user?.data?.fields?.SmallPhotoUrl?.value;
    }
}