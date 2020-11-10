import {api, LightningElement, track, wire} from 'lwc';
import {refreshApex} from '@salesforce/apex';

import categoryLabel from '@salesforce/label/c.Category'
import questionLabel from '@salesforce/label/c.Question'
import answerLabel from '@salesforce/label/c.Answer'
import imageLabel from '@salesforce/label/c.Image'
import yesLabel from '@salesforce/label/c.Yes'
import noLabel from '@salesforce/label/c.No'

import getKeyTaskWrappersForAccount from '@salesforce/apex/KeyTaskComponentController.getKeyTaskWrappersForAccount'
import saveCallCardKeyTasks from '@salesforce/apex/KeyTaskComponentController.saveCallCardKeyTasks'
import saveFile from '@salesforce/apex/KeyTaskComponentController.saveFile'
import ImageResizer from 'c/imageResizer'

import userId from '@salesforce/user/Id';

export default class CallcardGrid extends LightningElement {

  // Sample Ids in Config a1pg0000002J7KdAAK

  // Account Id
  @api
  recordId;

  @api
  keyTasksExists;

  @api
  saveAllKeyTasksPerAccountVisit = false;

  @api
  useBannerFunctionality = false;

  @api
  imageScaleRatio = null;

  @track
  keyTasks;

  keyTasksWireReference;

  @track
  uploadButtonDisabled = false;

  clonedData = false;

  resizedImages = [];

  // Dialog Variables
  @track
  dialogHeader;
  @track
  dialogIcon;
  @track
  dialogMessage;

  label = {
    categoryLabel,
    questionLabel,
    answerLabel,
    imageLabel,
    yesLabel,
    noLabel
  };


  connectedCallback() {
    console.log(`Id: ${this.recordId} saveAllKeyTasksPerAccountVisit: ${this.saveAllKeyTasksPerAccountVisit} imageScaleRatio: ${this.imageScaleRatio}`);
  }

  @wire(getKeyTaskWrappersForAccount, {
    accountId: '$recordId',
    useBannerFunctionality: '$useBannerFunctionality',
    saveAllKeyTasksPerAccountVisit: '$saveAllKeyTasksPerAccountVisit'
  })
  wiredKeyTasksFunction(result) {
    this.keyTasks = result;
    this.keyTasksWireReference = result;
    this.clonedData = false;
    this.uploadButtonDisabled = false;
  }

  @api
  save(callCardId) {
    if (!this.validate()) {
      return;
    }
    this.uploadButtonDisabled = true;
    this.cloneData();
    console.log('Save called in KeyTask component');
    if (this.keyTasks.data) {
      let today = new Date();
      let dateStr = today.getFullYear() + ('00'+(today.getMonth()+1)).slice(-2) + ('00'+today.getDate()).slice(-2);
      if (callCardId) {
        this.keyTasks.data.forEach(keyTaskWrapper => {
          keyTaskWrapper.keyTask.Unique_Key__c = keyTaskWrapper.keyTask.Key_Task_Template__c + '-' + keyTaskWrapper.keyTask.Account__c + '-' + userId + '-' + dateStr;
          keyTaskWrapper.keyTask.Call_Card__c = callCardId;
        });
      }
      console.log(`CallCardID: ${callCardId} Data: ${JSON.stringify(this.keyTasks.data)}`);
      saveCallCardKeyTasks({keyTaskWrappers: this.keyTasks.data})
          .then(result => {
            let imagesWithKeyTaskId = this.resizedImages.map(image => {
              let keyTask = result.find(({keyTaskTemplateId}) => keyTaskTemplateId === image.keyTaskTemplateId);
              image.parentId = keyTask.keyTask.Id;
              return image;
            });
            let allPromises = [];
            imagesWithKeyTaskId.forEach(image => {
              allPromises.push(saveFile({
                'idParent': image.parentId,
                'strFileName': image.filename,
                'base64Data': image.base64Data
              }));
            });
            Promise.all(allPromises).then(() => {
              this.resizedImages = [];
              refreshApex(this.keyTasksWireReference);
            });
          })
          .catch(error => {
            console.error(error.message, error);
            this.displayError(error);
          });
    }
  }

  @api
  generateEvent() {
    console.log('Generating event...');
    this.dispatchEvent(new CustomEvent('callcardsave', {bubbles: true, composed: true}));
  }

  initKeyTasks(event) {
    this.keyTasksExists = !this.keyTasksExists;
  }

  handleChange(event) {
    this.cloneData();
    if (this.keyTasks.data && event.target.dataset.id) {
      var result = this.keyTasks.data.find(keytask => keytask.keyTaskTemplateId === event.target.dataset.id);
      if (result) {
        result.response = event.target.checked;
        result.keyTask.Complete__c = event.target.checked;
        result.isDisplayRequiredPhoto = result.response && result.isPhotoRequired;
      }
    }
  }

  cloneData() {
    if (!this.clonedData) {
      this.clonedData = true;
      this.keyTasks = JSON.parse(JSON.stringify(this.keyTasks));
      console.log(`${JSON.stringify(this.keyTasks)}`);
    }
  }

  uploadFile(event) {
    this.uploadButtonDisabled = true;
    this.cloneData();
    console.log(`Upload Button Disabled: ${this.uploadButtonDisabled}`);
    let currentKeyTaskTemplateId = event.target.dataset.templateId;
    console.log(`Key Task Template ID: ${currentKeyTaskTemplateId}`);
    let fileContents;
    if (event.target.files.length > 0) {
      //let files = event.target.files;
      let file = event.target.files[0];
      this.getFilesFromInput(file)
          .then(this.resizeImage.bind(this))  // https://stackoverflow.com/questions/35481367/the-this-object-is-undefined-when-using-promise
          .then((resizedImage) => {
            fileContents = resizedImage.src.split(',')[1];
            let keyTask = this.keyTasks.data.find(({keyTaskTemplateId}) => keyTaskTemplateId === currentKeyTaskTemplateId);
            if (keyTask.numberOfNewPhotos) {
              keyTask.numberOfNewPhotos = keyTask.numberOfNewPhotos + 1;
            } else {
              keyTask.numberOfNewPhotos = 1;
            }
            this.resizedImages.push({
              keyTaskTemplateId: currentKeyTaskTemplateId,
              filename: file.name,
              base64Data: encodeURIComponent(fileContents)
            });
            this.uploadButtonDisabled = false;
          })
          .catch(error => {
            console.error(error.message, error);
            this.displayError(error);
          });
    } else {
      this.uploadButtonDisabled = false;
    }
  }

  getFilesFromInput(file) {
    return new Promise((resolve, reject) => {
      console.log('In Files From Input');
      var reader = new FileReader();
      reader.onload = (e) => {
        console.log('Onload Files From Input');
        resolve(e.target.result);
      };
      reader.readAsDataURL(file);
    });
  }

  resizeImage(imageInput) {
    console.log('Resize Image');
    return new Promise((resolve, reject) => {
      var image = document.createElement("img");
      image.dataImageScaleRatio = this.imageScaleRatio; // https://stackoverflow.com/questions/17578280/how-to-pass-parameters-into-image-load-event
      image.onload = () => {
        console.log('onload');
        try {
          var localImageResizer = new ImageResizer();
          localImageResizer.setConfig({keepExif: true, scaleRatio: this.dataImageScaleRatio, debug: true});
          console.log('Before Scale');
          localImageResizer.scaleImage(image, resolve);
          console.log('After Scale');
        } catch (error) {
          console.error(error.message, error);
        }
        console.log('after scale image');
      };
      image.src = imageInput;
    });
  }

  validate() {
    let keyTasksWithOutRequiredPictures = '';
    this.keyTasks.data.forEach(keyTask => {
      if (keyTask.isDisplayRequiredPhoto && !keyTask.numberOfNewPhotos && !keyTask.numberOfPhotos) {
        keyTasksWithOutRequiredPictures += keyTask.question + '<br>';
      }
    });
    if (keyTasksWithOutRequiredPictures) {
      const modal = this.template.querySelector('c-modal');
      this.uploadButtonDisabled = false;
      this.dialogHeader = 'Save Before Attaching Photos';
      this.dialogIcon = 'utility:warning';
      this.dialogMessage = 'Please attach all required photos before saving.<br>';
      this.dialogMessage += `Please complete the following key tasks:<br>${keyTasksWithOutRequiredPictures}`;
      modal.show();
      return false;
    } else {
      return true;
    }
  }

  handleHideModal() {
    const modal = this.template.querySelector('c-modal');
    modal.hide();
  }

  displayError(error) {
    this.uploadButtonDisabled = false;
    const modal = this.template.querySelector('c-modal');
    this.dialogHeader = error.statusText;
    this.dialogIcon = 'utility:error';
    this.dialogMessage = `An Error Occurred.<br>${error.body.message}`;
    modal.show();
  }

}