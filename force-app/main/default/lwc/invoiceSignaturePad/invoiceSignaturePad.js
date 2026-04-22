import { LightningElement, api } from 'lwc';
import signAndRegenerateInvoice from '@salesforce/apex/InvoiceManager.signAndRegenerateInvoice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh'; // 1. Import the new Refresh module

export default class InvoiceSignaturePad extends LightningElement {
    @api recordId; 
    isDrawing = false;
    canvas;
    ctx;

    renderedCallback() {
        if (!this.canvas) {
            this.canvas = this.template.querySelector('canvas');
            this.ctx = this.canvas.getContext('2d');
            this.canvas.width = this.canvas.offsetWidth;
            this.canvas.height = this.canvas.offsetHeight;
            this.ctx.lineWidth = 2;
            this.ctx.lineCap = 'round';
            this.ctx.strokeStyle = '#000000';
        }
    }

    handleMouseDown(event) { this.startDrawing(event.offsetX, event.offsetY); }
    handleMouseMove(event) { this.draw(event.offsetX, event.offsetY); }
    handleMouseUp() { this.stopDrawing(); }

    handleTouchStart(event) {
        let rect = this.canvas.getBoundingClientRect();
        this.startDrawing(event.touches[0].clientX - rect.left, event.touches[0].clientY - rect.top);
    }
    handleTouchMove(event) {
        event.preventDefault(); 
        let rect = this.canvas.getBoundingClientRect();
        this.draw(event.touches[0].clientX - rect.left, event.touches[0].clientY - rect.top);
    }
    handleTouchEnd() { this.stopDrawing(); }

    startDrawing(x, y) {
        this.isDrawing = true;
        this.ctx.beginPath();
        this.ctx.moveTo(x, y);
    }
    draw(x, y) {
        if (!this.isDrawing) return;
        this.ctx.lineTo(x, y);
        this.ctx.stroke();
    }
    stopDrawing() {
        this.isDrawing = false;
        this.ctx.closePath();
    }

    handleClear() { this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height); }
    handleCancel() { this.dispatchEvent(new CloseActionScreenEvent()); }

    handleSave() {
        const dataURL = this.canvas.toDataURL('image/png');
        
        signAndRegenerateInvoice({ orderId: this.recordId, base64Signature: dataURL })
            .then(() => {
                // 2. Change the toast so the user knows it's doing background work
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing',
                    message: 'Signature saved. Generating official PDF...',
                    variant: 'success'
                }));
                
                // 3. Close the modal immediately
                this.dispatchEvent(new CloseActionScreenEvent());

                // 4. Wait 2.5 seconds for the @future method to finish, then force the page to refresh!
                setTimeout(() => {
                    this.dispatchEvent(new RefreshEvent());
                }, 2500);

                // Odświeżenie okna
                // setTimeout(() => {
                //     window.location.reload();
                // }, 2500);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}