import { LightningElement, track } from 'lwc';

const SLIDES = [
    {
        id: 's1',
        badge: 'ApexSync · Motorsport Data Solutions',
        title: 'Welcome to ApexSync.',
        desc: 'Your premium platform for managing data and relationships in the world of motorsport. Fast. Precise. Reliable.',
        watermark: 'Platform'
    },
    {
        id: 's2',
        badge: 'Limited Offer · Spring 2025',
        title: '20% off all Data Packages.',
        desc: 'Take advantage of our seasonal discount on telemetry and analytics bundles. Available for season partners until end of month.',
        watermark: 'Offer'
    },
    {
        id: 's3',
        badge: 'New Product · Available Now',
        title: 'F1 Live Telemetry API 2025.',
        desc: 'Integrate real-time race data directly into your CRM. Now available for premium partners across all circuits.',
        watermark: 'Live'
    },
    {
        id: 's4',
        badge: 'Analytics · Race Intelligence',
        title: 'Race Strategy Analytics v2.',
        desc: 'Pit stop prediction, tyre degradation analysis, and driver performance ranking — for every track on the calendar.',
        watermark: 'Analytics'
    }
];

const INTERVAL = 4800;

export default class ApexSyncHomeBanner extends LightningElement {
    @track currentIndex = 0;

    slides = SLIDES;
    _slideTimer;
    _progressTimer;
    _startTime;

    connectedCallback() { this._play(); }
    disconnectedCallback() { this._stop(); }

    _setVar(name, value) {
        this.template.host.style.setProperty(name, value);
    }

    _play() {
        this._startTime = Date.now();
        this._slideTimer = setInterval(() => {
            this.currentIndex = (this.currentIndex + 1) % this.slides.length;
            this._setVar('--track-offset', `${this.currentIndex * 100}%`);
            this._setVar('--progress-w', '0%');
            this._startTime = Date.now();
        }, INTERVAL);
        this._progressTimer = setInterval(() => {
            const pct = Math.min(((Date.now() - this._startTime) / INTERVAL) * 100, 100);
            this._setVar('--progress-w', `${pct}%`);
        }, 40);
    }

    _stop() {
        clearInterval(this._slideTimer);
        clearInterval(this._progressTimer);
    }

    _goTo(i) {
        this._stop();
        this.currentIndex = i;
        this._setVar('--track-offset', `${i * 100}%`);
        this._setVar('--progress-w', '0%');
        this._play();
    }

    get dotList() {
        return this.slides.map((s, i) => ({
            i,
            cls: i === this.currentIndex ? 'dot dot-active' : 'dot'
        }));
    }

    handlePrev() { this._goTo((this.currentIndex - 1 + this.slides.length) % this.slides.length); }
    handleNext() { this._goTo((this.currentIndex + 1) % this.slides.length); }
    handleDot(e) { this._goTo(parseInt(e.currentTarget.dataset.idx, 10)); }
}