# YTÜ StaryUp Backend

Node.js + Express + TypeScript + PostgreSQL + Prisma backend for YTÜ StaryUp iOS app.

## Prerequisites

- Node.js 18+
- PostgreSQL 14+
- npm or yarn

## Setup

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your PostgreSQL credentials:

```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/staryup?schema=public"
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
PORT=3000
```

### 3. Create database

```bash
# Create PostgreSQL database
createdb staryup

# Or via psql
psql -U postgres -c "CREATE DATABASE staryup;"
```

### 4. Run migrations

```bash
npm run db:push
```

### 5. Start development server

```bash
npm run dev
```

Server runs at `http://localhost:3000`

## API Endpoints

### Auth

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/auth/register` | Register new user | No |
| POST | `/api/auth/login` | Login | No |
| GET | `/api/auth/me` | Get current user | Yes |
| PATCH | `/api/auth/me` | Update profile | Yes |

### Projects

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/projects` | List all projects | No |
| GET | `/api/projects/:id` | Get project details | No |
| POST | `/api/projects` | Create project | Yes |
| PATCH | `/api/projects/:id` | Update project | Yes (owner) |
| DELETE | `/api/projects/:id` | Delete project | Yes (owner) |
| POST | `/api/projects/:id/upvote` | Toggle upvote | Yes |

### Applications

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/applications` | Apply to project | Yes |
| GET | `/api/applications/my` | My applications | Yes |
| GET | `/api/applications/received` | Applications I received | Yes |
| PATCH | `/api/applications/:id/status` | Accept/Reject | Yes (owner) |
| DELETE | `/api/applications/:id` | Withdraw application | Yes |

## Request Examples

### Register

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@ytu.edu.tr", "password": "123456", "name": "Test User"}'
```

### Create Project

```bash
curl -X POST http://localhost:3000/api/projects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title": "AI Assistant", "description": "An AI powered student assistant", "category": "TECHNOLOGY"}'
```

## Categories

- `TECHNOLOGY`
- `SOCIAL`
- `FINANCE`
- `HEALTH`
- `EDUCATION`
- `ENTERTAINMENT`
- `OTHER`

## Database Management

```bash
# Open Prisma Studio (GUI)
npm run db:studio

# Generate Prisma client
npm run db:generate

# Create migration
npm run db:migrate
```

## Production Build

```bash
npm run build
npm start
```
