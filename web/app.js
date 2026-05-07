const APP = {
    open: false,
    data: null,
    tab: 'sell',
};

const NUI_TIMEOUT_MS = 8000;
const BUSY_FAILSAFE_MS = 12000;
let busyFailsafe = null;

function $(id) { return document.getElementById(id); }
function fmt(n) { return (n ?? 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ','); }
function esc(str) {
    return String(str ?? '').replace(/[&<>"']/g, (m) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]));
}

function icon(name) {
    const map = {
        sell: 'fa-tag',
        buyback: 'fa-rotate-left',
        contract: 'fa-file-contract',
        market: 'fa-store',
        rumor: 'fa-comment-dots',
        cash: 'fa-dollar-sign',
        demand: 'fa-chart-line',
        status: 'fa-circle',
        time: 'fa-clock',
        inventory: 'fa-box-open',
        bonus: 'fa-gift',
        crate: 'fa-box',
        chip: 'fa-coins',
        note: 'fa-note-sticky',
        action: 'fa-arrow-right',
        item: 'fa-cube'
    };
    const cls = map[name] || 'fa-circle';
    return `<span class="inline-ico"><i class="fas ${cls}"></i></span>`;
}

function categoryGlyph(category) {
    const map = {
        jewelry: 'fa-gem',
        electronics: 'fa-radio',
        vehicles: 'fa-car',
        tools: 'fa-screwdriver-wrench',
        contraband: 'fa-skull-crossbones',
        antiques: 'fa-landmark',
        materials: 'fa-cubes',
        misc: 'fa-box'
    };
    const cls = map[String(category || '').toLowerCase()] || 'fa-box';
    return `<i class="fas ${cls}"></i>`;
}

function sectionTitle(iconName, text) {
    return `<div class="section-title">${icon(iconName).replace('inline-ico', 'section-ico')}<span>${esc(text)}</span></div>`;
}

function itemVisual(image, category) {
    if (image) {
        return `
        <div class="itemicon has-image">
          <img src="${esc(image)}" alt="" class="itemimg" onerror="this.closest('.itemicon').classList.add('img-failed')" />
          <span class="itemicon-fallback">${categoryGlyph(category)}</span>
        </div>
      `;
    }

    return `<div class="itemicon">${categoryGlyph(category)}</div>`;
}

function itemCell(label, category, image) {
    return `
    <div class="itemcell">
      ${itemVisual(image, category)}
      <div class="itemmeta">
        <div class="itemname">${esc(label)}</div>
        <div class="small">${esc(category || 'uncategorized')}</div>
      </div>
    </div>
  `;
}

function emptyState(iconChar, title, copy) {
    return `
    <div class="empty-state">
      <div>
        <div class="empty-ico">${iconChar}</div>
        <div class="empty-title">${esc(title)}</div>
        <div class="empty-copy">${esc(copy)}</div>
      </div>
    </div>
  `;
}

function showToast(text) {
    const t = $('toast');
    if (!t) return;
    t.textContent = text;
    t.classList.remove('hidden');
    setTimeout(() => t.classList.add('hidden'), 2400);
}

function setBusy(busy) {
    const el = $('busy');
    if (!el) return;

    el.classList.toggle('hidden', !busy);

    if (busyFailsafe) {
        clearTimeout(busyFailsafe);
        busyFailsafe = null;
    }

    if (busy) {
        busyFailsafe = setTimeout(() => {
            console.warn('Busy failsafe fired');
            setBusy(false);
            showToast('Timed out');
        }, BUSY_FAILSAFE_MS);
    }
}

async function nui(endpoint, payload = {}, timeoutMs = NUI_TIMEOUT_MS) {
    const url = `https://${GetParentResourceName()}/${endpoint}`;

    const doFetch = async (signal) => {
        const res = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload),
            signal,
        });

        const text = await res.text();
        if (!text) return null;

        try {
            return JSON.parse(text);
        } catch {
            return text;
        }
    };

    try {
        if (typeof AbortController !== 'undefined') {
            const controller = new AbortController();
            const t = setTimeout(() => controller.abort(), timeoutMs);
            try {
                return await doFetch(controller.signal);
            } finally {
                clearTimeout(t);
            }
        }

        return await Promise.race([
            doFetch(undefined),
            new Promise((_, rej) => setTimeout(() => rej(new Error('timeout')), timeoutMs)),
        ]);
    } catch (e) {
        console.error('NUI fetch failed', endpoint, e);
        showToast(`NUI error (${endpoint})`);
        return null;
    }
}

function setTab(name) {
    APP.tab = name;
    document.querySelectorAll('.tab').forEach((b) => b.classList.toggle('active', b.dataset.tab === name));
    document.querySelectorAll('.tabview').forEach((v) => v.classList.toggle('active', v.id === `tab-${name}`));
    render();
}

function renderSell() {
    const items = (APP.data?.items || []);
    const shopId = APP.data?.shop?.id;
    const playerRep = Math.round(APP.data?.player?.rep || 0);
    const hotCount = items.filter((it) => it.hot).length;
    const lockedCount = items.filter((it) => it.repLocked).length;

    const rows = items.map((it) => {
        const hot = it.hot ? `<span class="badge hot">HOT +${it.heatPerUnit}</span>` : `<span class="badge good">Stable</span>`;
        const repLock = (it.repLocked && (it.requiredRep || 0) > 0) ? `<span class="badge warn">Requires Rep ${fmt(it.requiredRep)}</span>` : '';
        const repLine = (it.requiredRep || 0) > 0 ? `<div class="small itemrank ${it.repLocked ? 'locked' : 'unlocked'}">${it.repLocked ? `Locked until rep ${fmt(it.requiredRep)}` : `Unlocked at rep ${fmt(it.requiredRep)}`}</div>` : '';
        const disabled = (it.youHave <= 0 || it.repLocked) ? 'disabled' : '';
        const demand = `${it.demandRemaining}/${it.demandInitial}`;
        const id = `amt_${it.name}`;
        const rowClass = it.repLocked ? 'locked-row' : '';
        const actionTitle = it.repLocked ? `Requires Rep ${fmt(it.requiredRep)}` : 'Sell item';

        return `
      <tr class="${rowClass}">
        <td>${itemCell(it.label, it.category, it.image)}${repLine}</td>
        <td><span class="badge">${it.youHave}</span></td>
        <td><span class="badge">${demand}</span></td>
        <td><span class="badge">$${fmt(it.priceQuick)}</span></td>
        <td>${hot}</td>
        <td>
          <input id="${id}" class="input" type="number" min="1" max="${it.youHave}" value="${Math.min(1, it.youHave)}" ${disabled}/>
        </td>
        <td>
          <button class="btn actionbtn good" ${disabled} onclick="sell('${shopId}','${it.name}','quick','${id}')" title="${actionTitle}" aria-label="Quick Sale">
            <i class="fas fa-bolt"></i>
          </button>
          <div class="small pricehint">$${fmt(it.priceQuick)}</div>
        </td>
        <td>
          <button class="btn actionbtn accent" ${disabled} onclick="sell('${shopId}','${it.name}','negotiate','${id}')" title="${actionTitle}" aria-label="Negotiate">
            <i class="fas fa-comments-dollar"></i>
          </button>
          <div class="small pricehint">$${fmt(it.priceNegotiateMin)}–$${fmt(it.priceNegotiateMax)}</div>
        </td>
        <td>
          <button class="btn actionbtn" ${disabled} onclick="sell('${shopId}','${it.name}','appraise','${id}')" title="${actionTitle}" aria-label="Appraise">
            <i class="fas fa-magnifying-glass-dollar"></i>
          </button>
          <div class="small pricehint">$${fmt(it.priceAppraiseMin)}–$${fmt(it.priceAppraiseMax)}</div>
        </td>
      </tr>
    `;
    }).join('');

    return `
    <div class="info-grid">
      <div class="info-card">
        <div class="info-card-icon"><i class="fas fa-box-open"></i></div>
        <div class="info-card-copy">
          <div class="info-label">Catalog Items</div>
          <div class="info-value">${fmt(items.length)}</div>
        </div>
      </div>
      <div class="info-card">
        <div class="info-card-icon"><i class="fas fa-fire"></i></div>
        <div class="info-card-copy">
          <div class="info-label">Hot Listings</div>
          <div class="info-value">${fmt(hotCount)}</div>
        </div>
      </div>
      <div class="info-card">
        <div class="info-card-icon"><i class="fas fa-store"></i></div>
        <div class="info-card-copy">
          <div class="info-label">Shop Type</div>
          <div class="info-value">Standard</div>
        </div>
      </div>
    </div>


    ${sectionTitle('rumor', 'Sales Floor')}
    <div class="card rumor-card" style="margin-bottom:14px;">
      <div class="rumor-card-main">
        <div class="rumor-card-icon"><i class="fas fa-comment-dots"></i></div>
        <div class="rumor-card-copy">
          <div class="rumor-card-title">Ask for a rumor</div>
          <div class="small">Demand burns down as people sell. Prices adapt. Rumors hint what is paying best.</div>
        </div>
      </div>
      <button class="btn ghost" onclick="rumor('${shopId}')">Open rumor desk</button>
    </div>

    ${sectionTitle('sell', 'Inventory Trading Board')}
    <table class="table">
      <thead>
        <tr>
          <th>Item</th>
          <th>You</th>
          <th>Demand</th>
          <th>Quick</th>
          <th>Status</th>
          <th>Amt</th>
          <th>Quick</th>
          <th>Negotiate</th>
          <th>Appraise</th>
        </tr>
      </thead>
      <tbody>${rows || `<tr><td colspan="9">${emptyState('◌', 'No items configured', 'This pawnshop has no saleable item entries yet.')}</td></tr>`}</tbody>
    </table>
  `;
}

function renderBuyback() {
    const list = (APP.data?.buyback || []);
    if (list.length === 0) return emptyState('↺', 'No active buyback offers', 'Items you sold with buyback terms will appear here until they expire.');

    const rows = list.map((e) => {
        const id = `bb_${e.entryId}`;
        return `
      <tr>
        <td>${itemCell(e.label, e.shopLabel, e.image)}</td>
        <td><span class="badge">${e.amount}</span></td>
        <td><span class="badge">$${fmt(e.unitBuyback)}</span></td>
        <td><span class="badge">${Math.max(0, e.expiresIn)}s</span></td>
        <td><input id="${id}" class="input" type="number" min="1" max="${e.amount}" value="${Math.min(1, e.amount)}" /></td>
        <td><button class="btn good" onclick="buyback('${e.entryId}','${id}')">Buy back</button></td>
      </tr>
    `;
    }).join('');

    return `
    ${sectionTitle('buyback', 'Recovery Ledger')}
    <table class="table">
      <thead>
        <tr>
          <th>Item</th>
          <th>Qty</th>
          <th>Unit</th>
          <th>Expires</th>
          <th>Amt</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `;
}

function renderContract() {
    const c = APP.data?.contract;
    const shopId = APP.data?.shop?.id;

    if (!c) return emptyState('✦', 'No contract available', 'This location is not offering a special delivery contract right now.');

    const reqs = (c.requirements || []).map((r) => {
        const ok = (r.youHave || 0) >= (r.amount || 0);
        return `<li>${esc(r.label)} x${r.amount} <span class="small">(you: ${r.youHave}) ${ok ? '✓ ready' : '✗ missing'}</span></li>`;
    }).join('');

    return `
    ${sectionTitle('contract', 'Special Contract')}
    <div class="card contract-card">
      <div class="contract-card-main">
        <div class="contract-card-icon"><i class="fas fa-file-contract"></i></div>
        <div style="flex:1 1 420px; min-width: 0;">
          <div style="font-weight:900; font-size:18px; margin-bottom:4px;">${esc(c.label)}</div>
          <div class="small">${esc(c.description || '')}</div>
          <ul class="list">${reqs}</ul>
        </div>
      </div>
      <div style="flex:0 0 240px; width:240px; max-width:100%;">
        <div class="kv"><div class="k">Status</div><div class="v">${c.completed ? 'Completed' : 'Available'}</div></div>
        <div class="kv"><div class="k">Bonus Multiplier</div><div class="v">x${c.bonusMultiplier}</div></div>
        <div class="kv"><div class="k">Flat Bonus</div><div class="v">$${fmt(c.flatBonus)}</div></div>
        <div style="height:12px;"></div>
        <button class="btn good" style="width:100%;" ${c.completed ? 'disabled' : ''} onclick="completeContract('${shopId}')">Complete Contract</button>
      </div>
    </div>
  `;
}

function renderMarket() {
    const m = APP.data?.market;
    const events = (m?.events || []);
    const mult = (m?.categoryMult || {});
    const cats = (APP.data?.categories || {});

    const evHtml = events.length
        ? events.map((e) => {
            const applied = e.applied
                ? Object.entries(e.applied).map(([cat, v]) => `${esc(cats[cat] || cat)}: x${(v || 1).toFixed(2)}`).join(' · ')
                : '';
            return `<div class="card"><div style="font-weight:900; font-size:15px; margin-bottom:4px;">${esc(e.label)}</div><div class="small">${esc(e.description || '')}</div><div class="small" style="margin-top:8px;">${applied}</div></div>`;
        }).join('')
        : emptyState('▣', 'No major market events', 'The market is stable right now. Category multipliers below still apply.');

    const multRows = Object.entries(mult).map(([cat, v]) => (
        `<tr><td>${itemCell(cats[cat] || cat, cat)}</td><td><span class="badge">x${(v || 1).toFixed(2)}</span></td></tr>`
    )).join('');

    return `
    ${sectionTitle('market', 'Market Intelligence')}
    <div style="display:grid; gap:12px;">${evHtml}</div>
    <div class="card" style="margin-top:14px;">
      <div style="font-weight:900; margin-bottom:10px; font-size:15px;">Category Multipliers</div>
      <table class="table">
        <thead><tr><th>Category</th><th>Multiplier</th></tr></thead>
        <tbody>${multRows || `<tr><td colspan="2">No category multiplier data.</td></tr>`}</tbody>
      </table>
      <div class="small" style="margin-top:10px;">Generated at: ${m?.generatedAt || 0}</div>
    </div>
  `;
}

function render() {
    if (!APP.data) return;

    $('shopTitle').textContent = APP.data.shop?.label || 'Pawnshop';
    $('subTitle').textContent = 'Buyback, contracts, and a living market';
    $('repPill').textContent = `REP ${Math.round(APP.data.player?.rep || 0)}/${APP.data.player?.repMax || 100}`;
    $('heatPill').textContent = `HEAT ${Math.round(APP.data.player?.heat || 0)}/${APP.data.player?.heatMax || 100}`;

    $('tab-sell').innerHTML = renderSell();
    $('tab-buyback').innerHTML = renderBuyback();
    $('tab-contract').innerHTML = renderContract();
    $('tab-market').innerHTML = renderMarket();
}

window.sell = (shopId, item, mode, amtId) => {
    const amt = parseInt($(amtId).value || '0', 10);
    nui('sell', { shopId, item, amount: amt, mode });
};

window.buyback = (entryId, amtId) => {
    const amt = parseInt($(amtId).value || '0', 10);
    nui('buyback', { entryId, amount: amt });
};

window.completeContract = (shopId) => {
    nui('contract', { shopId });
};

window.rumor = (shopId) => {
    nui('rumor', { shopId });
};

function openRumor(r) {
    $('rumorTitle').textContent = r?.title || 'Market Rumor';
    const items = r?.items || [];
    const html = items.length
        ? `<ul class="list">${items.map((i) => `<li>${esc(i.label)} <span class="small">${i.decoy ? '(maybe?)' : '(verified)'}</span></li>`).join('')}</ul>`
        : `<div class="small">No rumor.</div>`;
    $('rumorBody').innerHTML = html;
    $('rumorModal').classList.remove('hidden');
}

function closeRumor() {
    $('rumorModal').classList.add('hidden');
}

$('closeBtn').addEventListener('click', () => nui('close', {}));
$('rumorClose').addEventListener('click', closeRumor);

document.querySelectorAll('.tab').forEach((b) => {
    b.addEventListener('click', () => setTab(b.dataset.tab));
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') nui('close', {});
});

window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled promise rejection', event.reason);
    showToast('UI error. Check F8 console.');
});

window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;

    if (msg.action === 'open') {
        setBusy(false);
        APP.open = true;
        APP.data = msg.data;
        document.body.classList.remove('hidden');
        setBusy(false);
        closeRumor();
        setTab('sell');
        render();
        return;
    }

    if (msg.action === 'update') {
        setBusy(false);
        APP.data = msg.data;
        render();
        return;
    }

    if (msg.action === 'close') {
        setBusy(false);
        APP.open = false;
        APP.data = null;
        document.body.classList.add('hidden');
        setBusy(false);
        closeRumor();
        return;
    }

    if (msg.action === 'busy') {
        setBusy(!!msg.busy);
        return;
    }

    if (msg.action === 'rumor') {
        setBusy(false);
        openRumor(msg.data);
        return;
    }

    if (msg.action === 'toast') {
        showToast(msg.text || '');
    }
});
