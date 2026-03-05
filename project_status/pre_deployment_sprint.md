# Pre-Deployment Sprint — Implementation Plan

This sprint focuses on the final crucial pieces of technical debt required before the platform can safely process real, sensitive production data and handle production-level traffic.

## 1. Performance & Scalability

### Goal
Ensure the application is highly responsive and can scale horizontally while managing intensive background tasks (like AI embeddings and scraping) without blocking the main web threads.

### Proposed Changes
1. **Database Indexing**: Run an audit to identify missing foreign key indexes and add them via migrations.
2. **Caching Strategy**: Implement Rails fragment caching (Russian Doll) for heavy views like the Compliance Dashboard and Active Tables. Configure Redis as the cache store in `production.rb`.
3. **Sidekiq Tuning**: Ensure Sidekiq is fully configured for production, including a dedicated queue for AI heavy-lifting (`:ai_tasks`), standard queues (`:default`), and potentially setting up `sidekiq-cron` for scheduled scraping tasks.

## 2. Security Enhancements

### Goal
Protect sensitive regulatory and organizational data, enforce strict access logging, and prevent abuse.

### Proposed Changes
1. **Audit Logging**: Add the `paper_trail` gem to track changes to critical models (`Regulation`, `Policy`, `ComplianceControl`, `Organization`). This provides an immutable history of who changed what and when.
2. **Encryption at Rest**: Utilize Rails 7 Active Record Encryption (`encrypts`) for highly sensitive fields (e.g., user PII, specific provider API keys, or custom extracted confidential data).
3. **Rate Limiting**: Integrate the `rack-attack` gem to throttle brute-force login attempts on Devise routes and prevent API abuse.
4. **Advanced Auth (2FA)**: Integrate `devise-two-factor` to offer Multi-Factor Authentication for users handling sensitive compliance data.

## 3. Testing & Quality Assurance

### Goal
Establish an automated safety net to prevent regressions when deploying new features or maintaining the highly complex AI and dynamic workflow engines.

### Proposed Changes
1. **CI/CD Pipeline**: Create a GitHub Actions workflow (`.github/workflows/ci.yml`) that runs tests, linters, and security checks on every push.
2. **Security Scanning**: Add `brakeman` (static code analysis for Rails vulnerabilities) and `bundler-audit` to the CI pipeline.
3. **Core Test Coverage**: Write RSpec system/request specs for:
   - Tenant isolation (ensuring Org A cannot see Org B's data).
   - Core workflow engine transitions.
   - Pundit authorization policies.
   - Core AI service stubs.
