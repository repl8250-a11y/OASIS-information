# OASIS-Research 🌴🏜️

## What is OASIS ?

ResearchOS is a unified research intelligence platform combining:
- Literature discovery (Sci-Hub + Google Scholar + arXiv)
- Knowledge management (Notion + Obsidian)
- Research gap identification
- AI-powered research assistance

**Mission:** Reduce academic research effort by 80%.

## Quick Start

### Prerequisites
- Docker & Docker Compose (for containerized development)
- Go 1.21+, Node.js 18+, Python 3.11+
- PostgreSQL 15+, Redis 7+, Qdrant 1.7+

### Development

```bash
# Clone repository
git clone https://github.com/researchos/researchos.git
cd researchos

# Copy environment template
cp .env.example .env

# Start all services (Docker)
docker-compose up -d

# Run migrations
make migrate

# Start development servers
make dev
