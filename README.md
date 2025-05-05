# Real Estate Listings App

A web application for managing and processing real estate listings with CSV upload functionality.

## Prerequisites

- Docker and Docker Compose
- Node.js and npm
- Ruby (for local development)

## Getting Started

### Backend Setup

```bash
cd backend
docker compose build
docker compose up
```

The backend API will be available at `http://localhost:3033`

### Frontend Setup

```bash
cd frontend/web
npm install
npm run dev
```

Please see result of `npm run dev` to confirm where the frontend will be available at

## Features

- CSV file upload and validation
- batch processing
- Error reporting and validation feedback (frontend will show which rows and which columns were invalid)
- Multi-language support (English/Japanese)