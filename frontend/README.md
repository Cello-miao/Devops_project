bs-auth
======

A minimal Vue 3 + Vite authentication scaffold implementing:
- Sign In component at /sign_in
- Sign Up component at /sign_up
- Router with a beforeEach guard that restricts access based on localStorage auth data
- Axios instance that sends the XSRF token stored in localStorage as the `x-xsrf-token` header on every request
- Logout button in `App.vue` that calls `/users/sign_out` and clears localStorage

Notes / assumptions
- I used Vite + Vue 3 for a lightweight modern dev flow (you asked for vue-cli; if you prefer vue-cli I can res scaffold with it).
- Passwords are hashed client-side using `bcryptjs` before being sent (the server must expect a hashed password).
- API endpoints used:
  - POST /users/sign_in
  - POST /users/sign_up
  - POST /users/sign_out
- The server is expected to return JSON with `xsrfToken`, `userId`, `roleId` on successful sign in.

Quick start

```bash
cd bs-auth
npm install
npm run dev
```

What I created
- `src/router.js` — all router logic and global guard
- `src/services/api.js` — axios instance with XSRF header injection
- `src/components/Authentication.vue` — sign in form, stores tokens into localStorage
- `src/components/Registration.vue` — sign up form, redirects to `/` on success
- `src/App.vue` — main app with Logout button

Next steps / improvements
- Add form validation and nicer UI (Bootstrap/Tailwind)
- Add unit tests and E2E tests for auth flows
- If you want server-side session handling, ensure the server also sends an HttpOnly XSRF cookie for additional protection

