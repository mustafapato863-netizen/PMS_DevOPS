# Phase 5 Part 5 — Database Persistence Implementation Plan

**Objective**: Move from in-memory JSON to persistent database storage  
**Status**: Planning  
**Estimated Duration**: 1-2 hours  
**Scope**: 10-15 backend files

---

## Current State (Parts 1-4)

### In-Memory Storage
- Teams stored in JSON files (`/Backend/config/teams/`)
- Onboarding state stored in memory only
- Alert configurations transient
- Dashboard visibility ephemeral

### Limitations
1. **Data Loss**: Onboarding state lost on restart
2. **No Audit Trail**: No history of changes
3. **Concurrent Access**: No database locking
4. **Backup/Recovery**: Requires file system backup

---

## Target State (Part 5)

### Database Persistence
- PostgreSQL for structured data
- SQLAlchemy ORM for type-safe access
- Async database operations
- Full ACID compliance

### New Capabilities
1. **Durable Storage**: All data persisted
2. **Audit Trail**: Track all changes
3. **Concurrent Access**: Database handles locking
4. **Transactions**: Atomic operations
5. **Migrations**: Version control for schema

---

## Implementation Roadmap

### Phase 5 Part 5 Milestones

#### Milestone 1: Database Schema (30 min)
- [ ] Design SQLAlchemy models
  - `Team` — Main team entity
  - `OnboardingState` — Track onboarding progress
  - `AlertRule` — Performance alert configuration
  - `DashboardWidget` — UI widget configuration
  - `AuditLog` — Change tracking

#### Milestone 2: SQLAlchemy Models (20 min)
- [ ] Create `Backend/database/models.py`
  - Async support
  - Relationships defined
  - Validators applied
  - Indexes on key fields

#### Milestone 3: Database Configuration (15 min)
- [ ] Create `Backend/database/config.py`
  - Database URL management
  - Connection pooling
  - Session management
  - Environment-based configuration

#### Milestone 4: Migrations (15 min)
- [ ] Set up Alembic
- [ ] Create initial migration
- [ ] Migration scripts for dev/prod

#### Milestone 5: Repository Layer (20 min)
- [ ] Create `Backend/database/repositories.py`
  - Async CRUD operations
  - Transaction support
  - Query helpers

#### Milestone 6: Service Updates (20 min)
- [ ] Update `TeamService` to use database
  - Replace JSON file I/O
  - Use repository layer
  - Maintain same API

#### Milestone 7: Onboarding Persistence (10 min)
- [ ] Create `OnboardingRepository`
- [ ] Track step completion
- [ ] Support resume on failure

#### Milestone 8: Integration & Testing (10 min)
- [ ] Update app.py for database setup
- [ ] Verify all endpoints work
- [ ] Test data persistence

---

## File Structure (New)

```
Backend/
├── database/
│   ├── __init__.py              # Exports
│   ├── config.py                # DB config + session
│   ├── models.py                # SQLAlchemy models
│   ├── repositories.py          # Async CRUD layer
│   └── migrations/              # Alembic migrations
│       ├── versions/
│       └── env.py
├── services/
│   └── team_service.py          # (Updated) Use DB instead of JSON
└── app.py                        # (Updated) Database init
```

---

## Key Design Decisions

### 1. SQLAlchemy Async
- Use `create_async_engine()`
- Async session factory
- Non-blocking database operations
- Compatible with FastAPI async

### 2. Repository Pattern
- Decouple services from database
- Testable services
- Easy to swap database backends
- Clear separation of concerns

### 3. Migrations with Alembic
- Version control for schema
- Easy rollback
- Reproducible deployments
- Dev/prod consistency

### 4. Audit Trail
- Track all changes
- User ID (if available)
- Timestamp on all records
- Soft deletes (mark as deleted, don't remove)

### 5. Relationships
- Team → OnboardingState (1:1)
- Team → AlertRule (1:N)
- Team → DashboardWidget (1:N)
- Team → AuditLog (1:N)

---

## Database Schema

### Teams Table
```sql
CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    region VARCHAR(50),
    description TEXT,
    kpi_keys JSONB,
    kpi_weights JSONB,
    team_lead VARCHAR(100),
    team_lead_email VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_name (name),
    INDEX idx_is_active (is_active)
);
```

### OnboardingStates Table
```sql
CREATE TABLE onboarding_states (
    id SERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL FOREIGN KEY REFERENCES teams(id),
    current_step INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    last_error TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_team_id (team_id)
);
```

### AlertRules Table
```sql
CREATE TABLE alert_rules (
    id SERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL FOREIGN KEY REFERENCES teams(id),
    metric_name VARCHAR(100) NOT NULL,
    threshold FLOAT NOT NULL,
    action VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_team_id (team_id)
);
```

### AuditLog Table
```sql
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    team_id INTEGER NOT NULL FOREIGN KEY REFERENCES teams(id),
    action VARCHAR(50) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_team_id (team_id),
    INDEX idx_created_at (created_at)
);
```

---

## Environment Configuration

### Development (.env)
```
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/pms_dev
SQLALCHEMY_ECHO=true
```

### Production (.env.prod)
```
DATABASE_URL=postgresql+asyncpg://user:pass@prod-db:5432/pms_prod
SQLALCHEMY_ECHO=false
```

---

## Migration Strategy

### Initial Migration (Part 5)
1. Create all tables
2. Load existing JSON configs into database
3. Set up indexes
4. Create audit trail for migration

### Future Migrations
- Add new columns as features expand
- Maintain backward compatibility
- Non-blocking migrations for production

---

## Testing Strategy

### Unit Tests
- Repository layer operations
- Service layer logic
- Model validation

### Integration Tests
- Database CRUD operations
- Transaction rollback
- Concurrent access

### End-to-End Tests
- API endpoints with real database
- Onboarding workflow persistence
- State recovery after restart

---

## Backward Compatibility

### Migration Path
1. **Step 1**: Load existing JSON configs into database
2. **Step 2**: Run with both JSON and database (dual-write)
3. **Step 3**: Verify data consistency
4. **Step 4**: Switch to database-only
5. **Step 5**: Archive JSON files

### Rollback Plan
- Keep JSON files as backup
- Database transaction support for rollback
- Versioned migrations for downgrade

---

## Dependencies to Add

```toml
[tool.poetry.dependencies]
sqlalchemy = "^2.0"
asyncpg = "^0.28"
alembic = "^1.12"
pydantic-sqlalchemy = "^0.2"
```

### Installation
```bash
cd Backend
pip install sqlalchemy asyncpg alembic
```

---

## Success Criteria

### Functionality
- [ ] All teams persisted to database
- [ ] Onboarding state tracked in database
- [ ] Alert rules durable
- [ ] API endpoints work unchanged
- [ ] Data survives restart

### Quality
- [ ] 0 compilation errors
- [ ] 100% type safety
- [ ] Full backward compatibility
- [ ] All tests pass
- [ ] Proper error handling

### Performance
- [ ] <100ms response time
- [ ] Connection pooling active
- [ ] No N+1 queries
- [ ] Efficient indexes

---

## Timeline Breakdown

| Phase | Duration | Files | Complexity |
|-------|----------|-------|-----------|
| Schema Design | 5 min | 0 | Low |
| SQLAlchemy Models | 20 min | 2 | Medium |
| DB Config | 10 min | 1 | Low |
| Repositories | 15 min | 1 | Medium |
| Service Updates | 15 min | 1 | Medium |
| Migrations | 10 min | 3 | Medium |
| Integration | 15 min | 2 | High |
| **Total** | **90 min** | **~10** | **Medium** |

---

## Next Steps After Part 5

### Phase 6: Advanced Features (Optional)
1. Authentication & Authorization
2. User management
3. Team permissions
4. Data export/import
5. Backup & restore

### Production Hardening
1. Database pooling optimization
2. Query performance tuning
3. Backup strategy
4. Disaster recovery
5. Monitoring & alerts

---

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|-----------|
| Data Migration | 🟡 Medium | Test migration scripts thoroughly |
| Performance | 🟢 Low | Add indexes, use connection pooling |
| Concurrent Access | 🟢 Low | Database handles locking |
| Breaking Changes | 🟢 Low | Maintain same service API |
| Backup Loss | 🟠 Medium | Keep JSON files as backup |

---

## Questions Before Starting

1. **PostgreSQL or SQLite?**
   - Recommendation: PostgreSQL for production, SQLite for dev
   
2. **Cloud Database or Local?**
   - Recommendation: Local for dev, cloud (AWS RDS) for prod

3. **Connection String Management?**
   - Recommendation: Environment variables + .env files

4. **Existing Data Migration?**
   - Recommendation: Write script to load JSON → Database

5. **Transaction Requirements?**
   - Recommendation: Use SQLAlchemy transactions for ACID

---

**Ready to begin Phase 5 Part 5 implementation.**

