## Contributing to OASIS🏜️

#### Code of Conduct

Be respectful, inclusive, and professional.

#### Development Setup

1. **Clone & Navigate**
```bash
git clone https://github.com/researchos/researchos.git
cd researchos

```
2.Environment
cp .env.example .env
#### Edit .env with your settings

3.Local Services
docker-compose up -d
make migrate
make dev
____
Workflow
Branch Naming

feature/short-description
bugfix/issue-number
refactor/area
docs/topic

____
Commit Messages
type(scope): description

[optional body]
[optional footer]

Examples:
feat(auth): add OAuth2 support
fix(discovery): resolve ranking bug in search
docs(api): update endpoint documentation

Pull Request Process

1.Create feature branch
2.Write tests
3.Ensure all tests pass: make test
4.Lint code: make lint
5.Submit PR with description
6.Address review feedback
7.Squash & merge when approved

Testing:
make test-service SERVICE=auth-service

Integration Tests:
make test-integration

End-to-End Tests:
make test-e2e


Code Standards
Go: Follow Uber Go style guide
TypeScript: ESLint config included
Python: Black formatter, mypy typing
Run make format before committing.

Documentation
Update docs/ for:

API changes
Architecture changes
New services
Configuration updates
Performance Considerations
Keep search latency <500ms
Maintain 99.5% uptime
Cache aggressively
Use async/workers for heavy tasks


Need Help?
Issues: GitHub Issues
Discussions: GitHub Discussions
Slack: #researchos-dev



