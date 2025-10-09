import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export function showSuccessToast(component, title, message) {
    if (!component || !component.dispatchEvent) return;
    component.dispatchEvent(new ShowToastEvent({ title, message, variant: 'success', mode: 'dismissible' }));
}

export function showErrorToast(component, title, message) {
    if (!component || !component.dispatchEvent) return;
    component.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error', mode: 'sticky' }));
}

export function showInfoToast(component, title, message) {
    if (!component || !component.dispatchEvent) return;
    component.dispatchEvent(new ShowToastEvent({ title, message, variant: 'info', mode: 'dismissible' }));
}

