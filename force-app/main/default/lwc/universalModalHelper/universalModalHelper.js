import { LightningElement } from 'lwc';

export default class UniversalModalHelper extends LightningElement {
    /**
     * Create field configuration for dynamic forms
     * @param {string} name - Field name
     * @param {string} type - Field type: 'text', 'textarea', 'combobox'
     * @param {object} config - Field configuration
     * @returns {object} Field configuration object
     */
    static createField(name, type, config = {}) {
        return {
            name: name,
            label: config.label || name,
            type: type,
            isText: type === 'text',
            isTextarea: type === 'textarea',
            isCombobox: type === 'combobox',
            required: config.required || false,
            placeholder: config.placeholder || '',
            defaultValue: config.defaultValue || '',
            value: config.value || config.defaultValue || '',
            options: config.options || [],
            icon: config.icon || null,
            helpText: config.helpText || null,
            rows: config.rows || 3
        };
    }

    /**
     * Create form configuration
     * @param {Array} fields - Array of field configurations
     * @returns {object} Form configuration object
     */
    static createFormConfig(fields) {
        return {
            fields: fields
        };
    }
}
