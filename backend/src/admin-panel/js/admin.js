// Admin Panel — shared utilities
const API_BASE = '/api/admin';

function getToken() {
  return localStorage.getItem('adminToken');
}

function requireAuth() {
  if (!getToken()) {
    window.location.href = '/admin/';
    return false;
  }
  return true;
}

function logout() {
  localStorage.removeItem('adminToken');
  localStorage.removeItem('adminName');
  window.location.href = '/admin/';
}

async function api(path, options = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${getToken()}`,
      ...options.headers,
    },
  });

  if (res.status === 401) {
    logout();
    return;
  }

  if (res.status === 204) return null;

  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Bir hata oluştu');
  return data;
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('tr-TR', {
    year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
  });
}

function formatCredits(amount) {
  const sign = amount > 0 ? '+' : '';
  const color = amount > 0 ? 'text-green-600' : amount < 0 ? 'text-red-600' : 'text-gray-600';
  return `<span class="${color} font-semibold">${sign}${amount}</span>`;
}

const txTypeLabels = {
  REGISTRATION_BONUS: { label: 'Kayıt Bonusu', color: 'bg-blue-100 text-blue-800' },
  UPVOTE_EARNED: { label: 'Upvote Kredisi', color: 'bg-green-100 text-green-800' },
  APPLICATION_ACCEPTED: { label: 'Kabul Kredisi', color: 'bg-purple-100 text-purple-800' },
  APPLICATION_SPENT: { label: 'Başvuru Maliyeti', color: 'bg-orange-100 text-orange-800' },
  ADMIN_ADJUSTMENT: { label: 'Admin İşlemi', color: 'bg-gray-100 text-gray-800' },
};

function txTypeBadge(type) {
  const t = txTypeLabels[type] || { label: type, color: 'bg-gray-100 text-gray-800' };
  return `<span class="px-2 py-1 text-xs rounded-full ${t.color}">${t.label}</span>`;
}

function navHTML(active) {
  const adminName = localStorage.getItem('adminName') || 'Admin';
  const items = [
    { href: '/admin/dashboard.html', label: 'Dashboard', id: 'dashboard' },
    { href: '/admin/users.html', label: 'Kullanıcılar', id: 'users' },
    { href: '/admin/projects.html', label: 'Projeler', id: 'projects' },
    { href: '/admin/transactions.html', label: 'Kredi Hareketleri', id: 'transactions' },
    { href: '/admin/config.html', label: 'Ayarlar', id: 'config' },
  ];

  return `
    <nav class="bg-white border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex items-center space-x-8">
            <a href="/admin/dashboard.html" class="flex items-center">
              <img src="/admin/img/logo.svg" alt="StaryUp" class="h-7">
            </a>
            ${items.map(i => `<a href="${i.href}" class="text-sm font-medium ${active === i.id ? 'text-primary-600 border-b-2 border-primary-600' : 'text-gray-500 hover:text-gray-700'} h-16 flex items-center">${i.label}</a>`).join('')}
          </div>
          <div class="flex items-center space-x-4">
            <span class="text-sm text-gray-600">${adminName}</span>
            <button onclick="logout()" class="text-sm text-red-600 hover:text-red-800 font-medium">Çıkış</button>
          </div>
        </div>
      </div>
    </nav>
  `;
}

function renderNav(active) {
  document.getElementById('nav').innerHTML = navHTML(active);
}

function paginate(current, total, onClick) {
  if (total <= 1) return '';
  let html = '<div class="flex items-center justify-center space-x-2 mt-6">';
  for (let i = 1; i <= total; i++) {
    html += `<button onclick="${onClick}(${i})" class="px-3 py-1 rounded ${i === current ? 'bg-primary-600 text-white' : 'bg-white text-gray-700 border hover:bg-gray-50'} text-sm">${i}</button>`;
  }
  html += '</div>';
  return html;
}
