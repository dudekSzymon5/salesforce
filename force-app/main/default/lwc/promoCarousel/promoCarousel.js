import { LightningElement, track } from 'lwc';

const TOTAL = 5;
const DURATION = 4500; // ms per slide

export default class PromoCarousel extends LightningElement {

    @track currentIndex = 0;
    @track progressWidth = 0;

    // Timer state (08:24:37 countdown)
    _totalSecs = 8 * 3600 + 24 * 60 + 37;
    _timerInterval;
    _autoInterval;
    _progressStart;
    _progressRaf;

    // ─── Lifecycle ────────────────────────────────────────────────────────────

    connectedCallback() {
        this._startAuto();
        this._startTimer();
    }

    disconnectedCallback() {
        clearInterval(this._autoInterval);
        clearInterval(this._timerInterval);
        cancelAnimationFrame(this._progressRaf);
    }

    // ─── Computed ─────────────────────────────────────────────────────────────

    get trackStyle() {
        return `transform: translateX(-${this.currentIndex * 20}%); transition: transform 0.55s cubic-bezier(0.4,0,0.2,1);`;
    }

    get progressStyle() {
        if (this.progressWidth === 0) {
            return 'width: 0%; transition: none;';
        }
        return `width: 100%; transition: width ${DURATION}ms linear;`;
    }

    get slides() {
        return Array.from({ length: TOTAL }, (_, i) => ({
            index: i,
            dotClass: i === this.currentIndex ? 'dot dot-active' : 'dot'
        }));
    }

    get timerH() { return this._pad(Math.floor(this._totalSecs / 3600)); }
    get timerM() { return this._pad(Math.floor((this._totalSecs % 3600) / 60)); }
    get timerS() { return this._pad(this._totalSecs % 60); }

    // ─── Navigation ───────────────────────────────────────────────────────────

    next() { this._goTo((this.currentIndex + 1) % TOTAL); }
    prev() { this._goTo((this.currentIndex - 1 + TOTAL) % TOTAL); }

    goTo(event) {
        const idx = parseInt(event.currentTarget.dataset.index, 10);
        this._goTo(idx);
    }

    _goTo(idx) {
        this.currentIndex = idx;
        this._startAuto();
    }

    // ─── Auto-advance ─────────────────────────────────────────────────────────

    _startAuto() {
        clearInterval(this._autoInterval);
        this._restartProgress();
        this._autoInterval = setInterval(() => {
            this.currentIndex = (this.currentIndex + 1) % TOTAL;
            this._restartProgress();
        }, DURATION);
    }

    _restartProgress() {
        // Reset to 0 then animate to 100 over DURATION
        this.progressWidth = 0;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.progressWidth = 100; }, 50);
    }

    // ─── Countdown timer ──────────────────────────────────────────────────────

    _startTimer() {
        this._timerInterval = setInterval(() => {
            if (this._totalSecs > 0) {
                this._totalSecs -= 1;
            }
        }, 1000);
    }

    _pad(n) { return String(n).padStart(2, '0'); }

    // ─── CTA handlers (extend as needed) ─────────────────────────────────────

    handleCTA()   { console.log('CTA: Explore offer'); }
    handleAbout() { console.log('CTA: About us'); }
    handlePromo() { console.log('CTA: Get it now'); }
    handleSale()  { console.log('CTA: Shop now'); }
}