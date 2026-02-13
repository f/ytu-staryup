# YTÜ StaryUp

> Fikirlerini paylaş, ekip bul — Share your ideas, find a team.

YTÜ StaryUp is a startup/project-sharing platform built for students at **Yıldız Teknik Üniversitesi (YTÜ)**. Post your startup ideas, discover projects from fellow students, upvote the ones you love, and apply to join teams.

## Features

- **Authentication** — Email/password registration & login with JWT-based sessions
- **Project Feed** — Browse projects with category filters, sort by newest or most popular, pull-to-refresh
- **Explore** — Discover projects by category, search and filter
- **Create Projects** — Share your startup idea with a title, description, and category
- **Project Detail** — Full project view with About and Applications tabs
- **Apply to Projects** — Apply with a role and message; project owners can accept or reject
- **Upvoting** — Upvote projects you like (one per user)
- **Notifications** — Track your sent applications and received applications
- **Profile** — View your stats, projects, and applications
- **Settings** — Manage account, logout, about page

### Categories

`Technology` · `Social` · `Finance` · `Health` · `Education` · `Entertainment` · `Other`

## Tech Stack

### iOS App

| Layer | Technology |
|-------|-----------|
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM (Model-View-ViewModel) |
| **Local Storage** | SwiftData |
| **Networking** | URLSession (native) |
| **Dependencies** | None — 100% Apple frameworks |

### Backend

| Layer | Technology |
|-------|-----------|
| **Runtime** | Node.js + TypeScript |
| **Framework** | Express.js |
| **Database** | PostgreSQL |
| **ORM** | Prisma |
| **Auth** | JWT + bcrypt |
| **Validation** | Zod |

## Project Structure

```
├── YTÜ StaryUp/                   # iOS App (SwiftUI)
│   ├── YTU__StaryUpApp.swift      # App entry point
│   ├── Models/                    # Data models (User, Project, Application, Category)
│   ├── Services/                  # API service & mock service
│   ├── ViewModels/                # MVVM view models
│   └── Views/
│       ├── Auth/                  # Login & registration
│       ├── Feed/                  # Feed, explore, notifications
│       ├── CreateProject/         # Project creation form
│       ├── Project/               # Project detail & apply sheet
│       ├── Profile/               # User profile
│       ├── Settings/              # Settings & about
│       └── Components/            # Reusable UI components
├── YTÜ StaryUp.xcodeproj/        # Xcode project
└── backend/                       # Node.js API
    ├── prisma/
    │   └── schema.prisma          # Database schema
    └── src/
        ├── index.ts               # Express server entry point
        ├── lib/prisma.ts          # Prisma client
        ├── middleware/             # Auth & error handling middleware
        └── routes/                # API route handlers
```

## Data Model

```
User
├── id, email, password, name, bio, avatarURL
├── projects[]      → Project (1:N)
├── applications[]  → Application (1:N)
└── upvotes[]       → Upvote (1:N)

Project
├── id, title, description, category, ownerId
├── applications[]  → Application (1:N)
└── upvotes[]       → Upvote (1:N)

Application
├── id, role, message, status (PENDING | ACCEPTED | REJECTED)
└── @@unique([projectId, applicantId])

Upvote
├── id, userId, projectId
└── @@unique([userId, projectId])
```

## Getting Started

### Prerequisites

- **iOS App**: Xcode 15+, iOS 17+
- **Backend**: Node.js 18+, PostgreSQL 14+

### Backend Setup

```bash
cd backend
npm install

# Configure environment
cp .env.example .env
# Edit .env with your PostgreSQL credentials and a secure JWT secret

# Create the database
createdb staryup

# Push the schema to the database
npm run db:push

# Start the development server
npm run dev
```

The API server will start at `http://localhost:3000`.

### iOS App Setup

1. Open `YTÜ StaryUp.xcodeproj` in Xcode
2. Make sure the backend is running on `localhost:3000`
3. The app uses `http://localhost:3000/api` in debug mode by default
4. Build and run on a simulator or device (iOS 17+)

> **Note**: No third-party dependencies required for the iOS app. It uses only Apple frameworks.

## API Overview

### Auth — `/api/auth`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/register` | Register new user | No |
| `POST` | `/login` | Login | No |
| `GET` | `/me` | Get current user | Yes |
| `PATCH` | `/me` | Update profile | Yes |

### Projects — `/api/projects`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/` | List all projects (filterable by category, sortable) | No |
| `GET` | `/:id` | Get project details with applications | No |
| `POST` | `/` | Create a project | Yes |
| `PATCH` | `/:id` | Update project | Yes (owner) |
| `DELETE` | `/:id` | Delete project | Yes (owner) |
| `POST` | `/:id/upvote` | Toggle upvote | Yes |
| `GET` | `/user/:userId` | Get a user's projects | No |

### Applications — `/api/applications`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/` | Apply to a project | Yes |
| `GET` | `/my` | List my applications | Yes |
| `GET` | `/received` | List applications I received | Yes |
| `PATCH` | `/:id/status` | Accept or reject an application | Yes (owner) |
| `DELETE` | `/:id` | Withdraw application | Yes (applicant) |

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:password@localhost:5432/staryup?schema=public` |
| `JWT_SECRET` | Secret key for signing JWT tokens | Use a strong random string |
| `PORT` | Server port | `3000` |

## Database Management

```bash
# Open Prisma Studio (visual database editor)
npm run db:studio

# Generate Prisma client after schema changes
npm run db:generate

# Push schema changes to database
npm run db:push

# Create a migration
npm run db:migrate
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with ❤️ at Yıldız Teknik Üniversitesi.

---

**Author**: [Fatih Kadir Akın](https://github.com/nicedoc)
