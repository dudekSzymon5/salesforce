import { LightningElement, track, wire } from 'lwc';
import getDashboardStats from '@salesforce/apex/HomeController.getDashboardStats';

export default class ApexSyncHomeDashboard extends LightningElement {
    @track stats = {};
    @track isLoading = true;

    @wire(getDashboardStats)
    wiredStats({ error, data }) {
    if (data) {
        this.stats = data;
        this.isLoading = false;
        // Set CSS var after render
        Promise.resolve().then(() => {
            const r = Math.min(data.conversionRate || 0, 100);
            this.template.host.style.setProperty('--conv-w', `${r}%`);
        });
    } else if (error) {
        console.error('HomeController error:', error);
        this.isLoading = false;
    }
}

    get conversionStyle() {
        const r = Math.min(this.stats.conversionRate || 0, 100);
        return `width: ${r}%`;
    }

    get pipelineFormatted() {
        const v = this.stats.pipelineValue || 0;
        if (v >= 1_000_000) return `$${(v / 1_000_000).toFixed(1)}M`;
        if (v >= 1_000)     return `$${(v / 1_000).toFixed(0)}K`;
        return `$${v}`;
    }
}