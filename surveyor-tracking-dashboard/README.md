# 🚀 Surveyor Tracking Dashboard

A modern, beautiful React dashboard for real-time and historical surveyor tracking! 🌍📍

---

## ✨ Features

- 🛰️ **Live Tracking:** See surveyors move in real time on the map
- 🕰️ **Historical Routes:** Pick any date range to view past movements
- 🔎 **Advanced Filters:** Filter by surveyor, city, project, and date
- 🗺️ **Interactive Map:** Powered by Leaflet + OpenStreetMap
- 👤 **Surveyor Management:** Add, edit, and manage surveyors (with backend)
- 🔌 **WebSocket Status:** Instantly see if live updates are connected
- 📱 **Responsive UI:** Works great on desktop and tablets

---

## ⚡ Quick Start

1. **Install dependencies:**
   ```sh
   npm install
   ```
2. **Start the app:**
   ```sh
   npm start
   ```
   Open [http://localhost:3000](http://localhost:3000) in your browser 🚦

3. **Backend:**
   - Requires backend API at `http://localhost:6565` (Spring Boot)
   - Make sure CORS is enabled for port 3000

---

## 🛠️ Usage

- Use the **filter bar** at the top to select:
  - 👤 Surveyor
  - 🏙️ City
  - 🏗️ Project
  - 📅 Date range
- Click **⚡ Start Live Tracking** for real-time, or **📘 Fetch Historical** for past routes
- The **map** shows the selected surveyor’s path
- **WebSocket status** (🟢/🔴) shows live connection
- **Surveyors** button opens management modal (if enabled)

---

## 🗂️ Project Structure

- `src/pages/LiveTrackingPage.jsx` — Main dashboard page
- `src/components/` — UI components (forms, tables, modals)
- `src/config.js` — App config (API endpoints)
- `public/` — Static assets

---

## 🧰 Tech Stack

- ⚛️ React (hooks)
- 🗺️ Leaflet + react-leaflet
- 📅 react-datepicker
- 🎨 @mui/material
- 🔗 STOMP over SockJS (WebSocket)
- 🌐 OpenStreetMap

---

## 📦 Scripts

- `npm start` — Start dev server
- `npm run build` — Production build
- `npm test` — Run tests

---

## 📝 Notes

- Requires backend API running and accessible
- For live tracking, backend WebSocket endpoint must be reachable
- For backend setup, see the backend project’s README

---

💡 **Questions? Feature requests?** Open an issue or contact the maintainer!
