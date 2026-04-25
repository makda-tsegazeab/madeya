const t = 'fake-token';
const reqs = [
  '/users/me/password',
  '/users/password',
  '/auth/password',
  '/auth/changePassword',
  '/user/change-password'
];
for(const r of reqs) {
  fetch('https://mk-fuel-monitor.up.railway.app' + r, { method: 'POST', headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + t}, body: JSON.stringify({currentPassword: 'old', newPassword: 'new'})}).then(async res => console.log(r, res.status));
  fetch('https://mk-fuel-monitor.up.railway.app' + r, { method: 'PATCH', headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + t}, body: JSON.stringify({currentPassword: 'old', newPassword: 'new'})}).then(async res => console.log('PATCH ' + r, res.status));
}
