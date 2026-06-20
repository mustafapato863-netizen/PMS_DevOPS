# Design Document: Phase 5 Part 5 - Authentication, Optimization, Advanced Features & Monitoring

## Overview

This design document outlines a comprehensive enterprise-grade system architecture for the PMS Dashboard, built on the database foundation established in Phase 5 Part 1-4. It implements secure authentication using JWT tokens with bcrypt hashing, a hierarchical role-based access control system supporting four role levels, and advanced data management features including soft deletes and versioning. Performance optimization is achieved through Redis caching, query optimization with composite indexes, and batch processing for large datasets. The architecture includes complete audit trails for compliance, health monitoring endpoints, error tracking with alerting, and a containerized deployment pipeline supporting both Kubernetes and docker-compose environments.

## Architecture Overview

```mermaid
graph TB
    subgraph "Client Layer"
        Web[Web Browser]
        Mobile[Mobile App]
        Admin[Admin Panel]
    end
    
    subgraph "API Gateway & Auth"
        Gateway[API Gateway]
        AuthMiddleware[Auth Middleware]
        RBACMiddleware[RBAC Middleware]
    end
    
    subgraph "Application Services"
        AuthService[Authentication Service]
        UserService[User Management]
        PerformanceService[Performance Service]
        BatchService[Batch Processing]
        AuditService[Audit & Versioning]
    end
    
    subgraph "Data Cache Layer"
        RedisCache[Redis Cache<br/>Performance Data]
        SessionCache[In-Memory<br/>Session Cache]
        ConfigCache[Config Cache<br/>4-hour TTL]
    end
    
    subgraph "Database Layer"
        CoreDB[(PostgreSQL<br/>Core DB)]
        AuditDB[(Audit Table<br/>Versioning)]
        ArchiveDB[(Archive DB<br/>Old Records)]
    end
    
    subgraph "Monitoring & Observability"
        HealthCheck[Health Check<br/>Endpoint]
        ErrorTracker[Error Tracking<br/>Service]
        Logger[Structured<br/>Logger]
        AlertService[Alert Service]
    end
    
    subgraph "Infrastructure"
        Docker[Docker<br/>Container]
        K8s[Kubernetes<br/>Orchestration]
        DockerCompose[Docker Compose<br/>Single Host]
    end
    
    Web --> Gateway
    Mobile --> Gateway
    Admin --> Gateway
    
    Gateway --> AuthMiddleware
    AuthMiddleware --> RBACMiddleware
    RBACMiddleware --> AuthService
    RBACMiddleware --> UserService
    RBACMiddleware --> PerformanceService
    RBACMiddleware --> BatchService
    
    AuthService --> RedisCache
    PerformanceService --> RedisCache
    PerformanceService --> SessionCache
    UserService --> ConfigCache
    
    AuthService --> CoreDB
    PerformanceService --> CoreDB
    BatchService --> CoreDB
    AuditService --> AuditDB
    PerformanceService --> ArchiveDB
    
    HealthCheck --> CoreDB
    HealthCheck --> RedisCache
    
    ErrorTracker --> Logger
    ErrorTracker --> AlertService
    Logger --> CoreDB
    
    Docker --> K8s
    Docker --> DockerCompose


## 1. Authentication & Security Architecture

### 1.1 Authentication Flow

```mermaid
sequenceDiagram
    participant Client as Client
    participant API as API Gateway
    participant AuthSvc as Auth Service
    participant DB as Database
    participant Cache as Redis Cache
    participant Middleware as Auth Middleware
    
    Client->>API: POST /login (username, password)
    API->>AuthSvc: validate_credentials()
    AuthSvc->>DB: query users table
    DB-->>AuthSvc: user record + password_hash
    AuthSvc->>AuthSvc: bcrypt.verify(password, hash)
    AuthSvc->>DB: update last_login
    AuthSvc->>AuthSvc: generate JWT token
    AuthSvc->>Cache: store session data
    AuthSvc-->>Client: HTTP 200 {token, user}
    
    Client->>API: GET /api/data (Authorization: Bearer token)
    API->>Middleware: validate_token()
    Middleware->>Middleware: jwt.verify(token)
    Middleware->>Cache: get session data
    Cache-->>Middleware: session data
    Middleware->>API: request allowed
    API-->>Client: HTTP 200 {data}


### 1.2 Core Interfaces & Types

```python
# Authentication Models
class User(Base):
    """User account with authentication credentials"""
    __tablename__ = "users"
    
    id: UUID = Column(UUID(as_uuid=True), primary_key=True)
    username: str = Column(String(100), unique=True, nullable=False)
    email: str = Column(String(255), unique=True, nullable=False)
    password_hash: str = Column(Text, nullable=False)  # bcrypt hash
    role: str = Column(String(50), default="Viewer")  # Admin, Manager, Executive, Viewer
    is_active: bool = Column(Boolean, default=True)
    failed_login_attempts: int = Column(Integer, default=0)
    locked_until: DateTime = Column(DateTime(timezone=True), nullable=True)
    last_login: DateTime = Column(DateTime(timezone=True), nullable=True)
    created_at: DateTime = Column(DateTime(timezone=True), server_default=func.now())
    updated_at: DateTime = Column(DateTime(timezone=True), onupdate=func.now())

class JWTToken(BaseModel):
    """JWT token payload"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 3600  # 1 hour
    
class PasswordResetRequest(BaseModel):
    """Password reset token"""
    token: str
    expires_at: DateTime
    user_id: UUID
    used: bool = False

class SessionData(BaseModel):
    """In-memory session cache"""
    user_id: UUID
    username: str
    email: str
    role: str
    permissions: List[str]
    team_assignments: List[TeamAssignment]
    created_at: DateTime
    last_activity: DateTime
```

### 1.3 Authentication Service

```python
class AuthenticationService:
    """
    Handles user authentication with JWT tokens and bcrypt password hashing.
    
    Preconditions:
    - User exists in database with valid email and password_hash
    - password_hash is computed with bcrypt 12+ salt rounds
    - JWT secret key is securely stored in environment
    
    Postconditions:
    - Token is valid for 1 hour
    - Failed attempts tracked and account locked after 5 failures
    - Last login timestamp updated on successful authentication
    """
    
    async def authenticate_user(
        self, 
        username: str, 
        password: str, 
        client_ip: str
    ) -> JWTToken:
        """
        Authenticate user and return JWT token
        
        Args:
            username: User's username
            password: Plaintext password to verify
            client_ip: Client IP for audit logging
            
        Returns:
            JWTToken with access_token and expiration
            
        Raises:
            HTTPException(401): Invalid credentials
            HTTPException(423): Account locked (5+ failed attempts)
        """
        # Precondition: Validate input format
        assert len(username) > 0 and len(password) > 0
        
        # Get user from database
        user = await db.query(User).filter(User.username == username).first()
        if not user:
            # Security: Don't reveal if user exists
            await log_failed_attempt(username, client_ip, "user_not_found")
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Check if account is locked
        if user.locked_until and user.locked_until > datetime.now():
            raise HTTPException(status_code=423, detail="Account locked")
        
        # Verify password with bcrypt
        if not bcrypt.verify(password, user.password_hash):
            user.failed_login_attempts += 1
            if user.failed_login_attempts >= 5:
                user.locked_until = datetime.now() + timedelta(minutes=15)
                await db.commit()
                raise HTTPException(status_code=423, detail="Account locked")
            await db.commit()
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        # Postcondition: Successful authentication
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login = datetime.now()
        await db.commit()
        
        # Generate JWT token
        token_data = {
            "sub": str(user.id),
            "username": user.username,
            "role": user.role,
            "exp": datetime.utcnow() + timedelta(hours=1),
            "iat": datetime.utcnow()
        }
        token = jwt.encode(token_data, JWT_SECRET, algorithm="HS256")
        
        # Store session in cache
        session_data = SessionData(
            user_id=user.id,
            username=user.username,
            email=user.email,
            role=user.role,
            permissions=await self.get_permissions(user.role),
            team_assignments=await self.get_team_assignments(user.id),
            created_at=datetime.now(),
            last_activity=datetime.now()
        )
        await cache.set(f"session:{user.id}", session_data, ex=3600)
        
        return JWTToken(access_token=token, expires_in=3600)
    
    async def validate_token(self, token: str) -> dict:
        """
        Validate JWT token and return payload
        
        Preconditions:
        - token is properly formatted JWT string
        - JWT secret key matches token signature
        
        Postconditions:
        - Returns decoded token payload if valid
        - Raises HTTPException(401) if invalid or expired
        """
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token expired")
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Invalid token")
    
    async def create_user(
        self,
        username: str,
        email: str,
        password: str,
        role: str = "Viewer"
    ) -> User:
        """
        Create new user with hashed password
        
        Preconditions:
        - password meets security requirements (12+ chars, complexity)
        - username and email are unique
        - role is in {Admin, Manager, Executive, Viewer}
        
        Postconditions:
        - User created with bcrypt hashed password (12+ salt rounds)
        - Password never stored in plaintext
        - User returned with all fields except password_hash
        """
        # Validate password strength
        self._validate_password_strength(password)
        
        # Check uniqueness
        existing = await db.query(User).filter(
            (User.username == username) | (User.email == email)
        ).first()
        if existing:
            raise ValueError("Username or email already exists")
        
        # Hash password with bcrypt
        password_hash = bcrypt.hashpw(
            password.encode('utf-8'), 
            bcrypt.gensalt(rounds=12)
        ).decode('utf-8')
        
        # Create user
        user = User(
            username=username,
            email=email,
            password_hash=password_hash,
            role=role,
            is_active=True
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        return user
    
    def _validate_password_strength(self, password: str) -> None:
        """
        Validate password meets security requirements
        
        Requirements:
        - Minimum 12 characters
        - At least 1 uppercase letter
        - At least 1 lowercase letter
        - At least 1 digit
        - At least 1 special character
        """
        if len(password) < 12:
            raise ValueError("Password must be at least 12 characters")
        if not re.search(r'[A-Z]', password):
            raise ValueError("Password must contain uppercase letter")
        if not re.search(r'[a-z]', password):
            raise ValueError("Password must contain lowercase letter")
        if not re.search(r'\d', password):
            raise ValueError("Password must contain digit")
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            raise ValueError("Password must contain special character")
```


## 2. Role-Based Access Control (RBAC) System

### 2.1 Role Hierarchy

```
┌─────────────────────────────────────────┐
│           Role Hierarchy                │
├─────────────────────────────────────────┤
│  Admin (Root)                           │
│  ├─ All permissions                     │
│  ├─ Team scoped or unrestricted         │
│  └─ Can manage all users                │
├─────────────────────────────────────────┤
│  Manager (Team Lead)                    │
│  ├─ view_reports (own teams)            │
│  ├─ edit_performance (own teams)        │
│  ├─ manage_team_members                 │
│  ├─ upload_data (own teams)             │
│  └─ export_data (own teams)             │
├─────────────────────────────────────────┤
│  Executive (C-Suite)                    │
│  ├─ view_reports (all teams)            │
│  ├─ view_aggregated_analytics           │
│  ├─ export_data (all teams)             │
│  └─ readonly access                     │
├─────────────────────────────────────────┤
│  Viewer (Read-Only)                     │
│  ├─ view_reports (assigned teams only)  │
│  └─ No write permissions                │
└─────────────────────────────────────────┘
```

### 2.2 Permission Matrix

```python
# Permission definitions
PERMISSION_MATRIX = {
    "Admin": [
        "create_team", "delete_team", "edit_team_config",
        "upload_data", "edit_performance", "delete_performance",
        "view_reports", "export_data", "manage_users",
        "manage_permissions", "view_audit_logs", "restore_data",
        "manage_batch_operations", "configure_kpi",
        "manage_alerts", "view_system_metrics"
    ],
    "Manager": [
        "upload_data", "edit_performance", "view_reports",
        "export_data", "manage_team_members", "view_actions",
        "create_actions", "manage_team_kpi"
    ],
    "Executive": [
        "view_reports", "export_data", "view_aggregated_analytics",
        "view_audit_logs"
    ],
    "Viewer": [
        "view_reports"
    ]
}

class RolePermission(Base):
    """Junction table linking roles to permissions"""
    __tablename__ = "role_permissions"
    
    id: UUID = Column(UUID(as_uuid=True), primary_key=True)
    role: str = Column(String(50), nullable=False)
    permission: str = Column(String(100), nullable=False)
    created_at: DateTime = Column(DateTime(timezone=True), server_default=func.now())
    
    __table_args__ = (
        UniqueConstraint('role', 'permission', name='uq_role_permission'),
    )
```

### 2.3 Authorization Middleware

```python
class AuthorizationMiddleware:
    """
    Enforces role-based access control on API endpoints
    
    Preconditions:
    - User is authenticated (JWT token valid)
    - User has role in {Admin, Manager, Executive, Viewer}
    - User's permissions cached in Redis
    
    Postconditions:
    - Request allowed if user has required permission
    - HTTP 403 Forbidden returned if permission denied
    - Permission check cached for 5 minutes
    """
    
    async def check_permission(
        self,
        user_id: UUID,
        permission: str,
        resource_id: UUID = None,
        team_id: UUID = None
    ) -> bool:
        """
        Check if user has permission for operation
        
        Args:
            user_id: User ID
            permission: Required permission string
            resource_id: Optional resource (for team-scoped access)
            team_id: Optional team ID (for team-scoped access)
            
        Returns:
            True if permitted, False otherwise
        """
        # Get cached session data
        session_data = await cache.get(f"session:{user_id}")
        if not session_data:
            session_data = await self._load_session(user_id)
        
        # Admin has all permissions
        if session_data.role == "Admin":
            # Check if team-scoped admin
            if team_id:
                return await self._check_team_assignment(user_id, team_id)
            return True
        
        # Check if permission in user's role permissions
        if permission not in session_data.permissions:
            return False
        
        # For team-scoped operations, check team assignment
        if team_id:
            return await self._check_team_assignment(user_id, team_id)
        
        return True
    
    async def _check_team_assignment(
        self,
        user_id: UUID,
        team_id: UUID
    ) -> bool:
        """
        Check if user is assigned to team
        
        Preconditions:
        - team_id exists in teams table
        - user_id exists in users table
        
        Postconditions:
        - Returns True if user_team_assignments record exists
        - Result cached for 1 hour
        """
        cache_key = f"team_assignment:{user_id}:{team_id}"
        cached = await cache.get(cache_key)
        if cached is not None:
            return cached
        
        assignment = await db.query(UserTeamAssignment).filter(
            (UserTeamAssignment.user_id == user_id) &
            (UserTeamAssignment.team_id == team_id)
        ).first()
        
        result = assignment is not None
        await cache.set(cache_key, result, ex=3600)
        return result
    
    async def _load_session(self, user_id: UUID) -> SessionData:
        """Load session from database and cache"""
        user = await db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        
        permissions = await self._get_permissions_by_role(user.role)
        team_assignments = await db.query(UserTeamAssignment).filter(
            UserTeamAssignment.user_id == user_id
        ).all()
        
        session_data = SessionData(
            user_id=user.id,
            username=user.username,
            email=user.email,
            role=user.role,
            permissions=permissions,
            team_assignments=team_assignments,
            created_at=datetime.now(),
            last_activity=datetime.now()
        )
        
        await cache.set(f"session:{user_id}", session_data, ex=3600)
        return session_data
```


## 3. Database Query Optimization Strategy

### 3.1 Index Strategy

```sql
-- Composite indexes for common queries
CREATE INDEX idx_performance_employee_month_year 
    ON performance_records (employee_id, month, year);

CREATE INDEX idx_performance_team_month_year 
    ON performance_records (team_id, month, year);

CREATE INDEX idx_performance_year 
    ON performance_records (year);  -- Partition key

CREATE INDEX idx_kpi_values_record 
    ON kpi_values (record_id, record_year);

CREATE INDEX idx_users_username 
    ON users (username);

CREATE INDEX idx_user_team_assignments_user 
    ON user_team_assignments (user_id, team_id);

CREATE INDEX idx_audit_log_table_record 
    ON audit_log (table_name, record_id, performed_at DESC);

-- Partial indexes for active records
CREATE INDEX idx_employees_active 
    ON employees (team_id) 
    WHERE is_active = true;

CREATE INDEX idx_teams_active 
    ON teams (id) 
    WHERE is_active = true;

-- JSONB indexes for audit logs
CREATE INDEX idx_audit_log_new_values 
    ON audit_log USING GIN (new_values);

CREATE INDEX idx_audit_log_old_values 
    ON audit_log USING GIN (old_values);
```

### 3.2 Query Optimization Patterns

```python
class QueryOptimizer:
    """
    Implements query optimization patterns including:
    - Eager loading with SQLAlchemy joinedload
    - Pagination to limit result sets
    - Composite indexes for common filter combinations
    - Query result caching
    
    Preconditions:
    - Indexes created on frequently filtered columns
    - Result set size limited to 100 records per page
    - TTL cache configured with 1-hour expiration
    
    Postconditions:
    - Queries execute in < 10ms (indexed)
    - Pagination queries complete in < 50ms
    - N+1 query problems eliminated
    """
    
    async def get_performance_records(
        self,
        employee_id: UUID,
        month: str,
        year: int,
        page: int = 1,
        limit: int = 100
    ) -> List[PerformanceRecord]:
        """
        Get performance records with eager loading
        
        Query Optimization:
        - Uses composite index (employee_id, month, year)
        - Eager loads kpi_values relationship with joinedload
        - Uses pagination to limit result set
        - Target: < 10ms execution time
        
        Cache:
        - key: "performance:{employee_id}:{month}:{year}:{page}"
        - ttl: 3600 seconds (1 hour)
        """
        cache_key = f"performance:{employee_id}:{month}:{year}:{page}"
        
        # Check cache first
        cached = await cache.get(cache_key)
        if cached:
            return cached
        
        # Database query with eager loading
        offset = (page - 1) * limit
        records = await db.query(PerformanceRecord).options(
            joinedload(PerformanceRecord.employee),
            joinedload(PerformanceRecord.kpi_values)
        ).filter(
            (PerformanceRecord.employee_id == employee_id) &
            (PerformanceRecord.month == month) &
            (PerformanceRecord.year == year)
        ).offset(offset).limit(limit).all()
        
        # Cache result
        await cache.set(cache_key, records, ex=3600)
        return records
    
    async def get_team_performance_aggregated(
        self,
        team_id: UUID,
        month: str,
        year: int
    ) -> dict:
        """
        Get aggregated team performance
        
        Optimization:
        - Single query with aggregation
        - Result cached with key pattern for invalidation
        - Uses index on (team_id, month, year)
        
        Cache:
        - key: "team_performance:{team_id}:{month}:{year}"
        - ttl: 3600 seconds
        """
        cache_key = f"team_performance:{team_id}:{month}:{year}"
        
        # Check cache
        cached = await cache.get(cache_key)
        if cached:
            return cached
        
        # Aggregate query
        from sqlalchemy import func
        result = await db.query(
            func.count(PerformanceRecord.id).label("total_records"),
            func.avg(PerformanceRecord.score).label("avg_score"),
            func.max(PerformanceRecord.score).label("max_score"),
            func.min(PerformanceRecord.score).label("min_score")
        ).filter(
            (PerformanceRecord.team_id == team_id) &
            (PerformanceRecord.month == month) &
            (PerformanceRecord.year == year)
        ).first()
        
        aggregated = {
            "total_records": result.total_records,
            "average_score": float(result.avg_score),
            "max_score": float(result.max_score),
            "min_score": float(result.min_score)
        }
        
        # Cache result
        await cache.set(cache_key, aggregated, ex=3600)
        return aggregated
    
    async def list_employees_paginated(
        self,
        team_id: UUID,
        page: int = 1,
        limit: int = 100
    ) -> PaginatedResponse:
        """
        List employees with pagination
        
        Optimization:
        - Composite index on (team_id, is_active)
        - Limits result set to 100 per page
        - Target: < 50ms for any table size
        
        Preconditions:
        - page >= 1
        - limit <= 100
        - Only active employees returned by default
        
        Postconditions:
        - Returns paginated results
        - Total count available
        - No N+1 queries
        """
        offset = (page - 1) * limit
        
        # Total count
        total = await db.query(func.count(Employee.id)).filter(
            (Employee.team_id == team_id) &
            (Employee.is_active == True)
        ).scalar()
        
        # Paginated data
        employees = await db.query(Employee).filter(
            (Employee.team_id == team_id) &
            (Employee.is_active == True)
        ).offset(offset).limit(limit).all()
        
        return PaginatedResponse(
            data=employees,
            total=total,
            page=page,
            page_size=limit,
            total_pages=(total + limit - 1) // limit
        )
```

### 3.3 Partition Strategy

```python
class PartitionManager:
    """
    Manages data partitioning by year for performance_records
    
    Strategy:
    - Partition key: year column in performance_records
    - Benefits: Faster queries on year range, efficient archival
    - Queries automatically route to relevant partition
    
    Preconditions:
    - performance_records has year as partition key
    - Queries filter by year when possible
    
    Postconditions:
    - Only relevant partition scanned
    - Query performance scales with partition size
    """
    
    async def archive_old_records(self, years_to_retain: int = 3):
        """
        Archive performance records older than retention period
        
        Process:
        1. Copy records older than (current_year - years_to_retain) to archive
        2. Delete original records
        3. Analyze remaining table
        
        Preconditions:
        - Archive table exists
        - Sufficient disk space for temporary copy
        
        Postconditions:
        - Old records moved to archive
        - Table size reduced
        - Indexes refreshed
        """
        current_year = datetime.now().year
        cutoff_year = current_year - years_to_retain
        
        # Copy to archive
        await db.execute(f"""
            INSERT INTO performance_records_archive
            SELECT * FROM performance_records
            WHERE year < {cutoff_year}
        """)
        
        # Delete from main
        await db.execute(f"""
            DELETE FROM performance_records
            WHERE year < {cutoff_year}
        """)
        
        # Refresh statistics
        await db.execute("ANALYZE performance_records")
        await db.commit()
```


## 4. Caching Architecture

### 4.1 Redis Caching Strategy

```python
class CacheService:
    """
    Redis-based caching for performance data and computed results
    
    Cache Strategy:
    - Performance data: 1-hour TTL, key pattern: "performance:{emp_id}:{month}:{year}"
    - Team aggregations: 1-hour TTL, key pattern: "team_performance:{team_id}:{month}:{year}"
    - Sessions: 1-hour TTL, key pattern: "session:{user_id}"
    - Config: 4-hour TTL, key pattern: "config:{team_id}:kpi_weights"
    
    LRU Eviction:
    - Max memory: 500MB
    - Eviction policy: allkeys-lru
    - Evicts least-recently-used items when limit reached
    
    Preconditions:
    - Redis server running and accessible
    - Redis configured with maxmemory and eviction policy
    
    Postconditions:
    - Cached results returned in < 5ms
    - Stale data never served
    - Cache misses handled gracefully
    """
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.fallback_enabled = True
    
    async def get_performance_cache(
        self,
        employee_id: UUID,
        month: str,
        year: int
    ) -> Optional[List[dict]]:
        """
        Get performance data from cache
        
        Cache Key: "performance:{employee_id}:{month}:{year}"
        TTL: 3600 seconds (1 hour)
        """
        cache_key = f"performance:{employee_id}:{month}:{year}"
        
        try:
            cached = self.redis.get(cache_key)
            if cached:
                return json.loads(cached)
            return None
        except redis.ConnectionError:
            if self.fallback_enabled:
                return None  # Fall back to database
            raise
    
    async def set_performance_cache(
        self,
        employee_id: UUID,
        month: str,
        year: int,
        data: List[dict]
    ) -> None:
        """Store performance data in cache with 1-hour TTL"""
        cache_key = f"performance:{employee_id}:{month}:{year}"
        
        try:
            self.redis.setex(
                cache_key,
                3600,  # TTL in seconds
                json.dumps(data)
            )
        except redis.ConnectionError:
            # Log but don't fail - cache is optional
            logger.warning(f"Cache write failed for key {cache_key}")
    
    async def get_team_performance_cache(
        self,
        team_id: UUID,
        month: str,
        year: int
    ) -> Optional[dict]:
        """Get aggregated team performance from cache"""
        cache_key = f"team_performance:{team_id}:{month}:{year}"
        
        try:
            cached = self.redis.get(cache_key)
            if cached:
                return json.loads(cached)
            return None
        except redis.ConnectionError:
            return None
    
    async def set_team_performance_cache(
        self,
        team_id: UUID,
        month: str,
        year: int,
        data: dict
    ) -> None:
        """Store team performance aggregation in cache"""
        cache_key = f"team_performance:{team_id}:{month}:{year}"
        
        try:
            self.redis.setex(cache_key, 3600, json.dumps(data))
        except redis.ConnectionError:
            logger.warning(f"Cache write failed for key {cache_key}")

class CacheInvalidationService:
    """
    Manages cache invalidation patterns for data consistency
    
    Invalidation Strategy:
    - On create: No invalidation needed
    - On update: Invalidate specific entry and related aggregations
    - On delete: Invalidate all related cache entries
    
    Preconditions:
    - Cache keys follow consistent naming pattern
    - Services track which cache keys to invalidate
    
    Postconditions:
    - Invalid cache entries removed immediately
    - Aggregations recalculated on next access
    - Data consistency maintained
    """
    
    async def invalidate_performance_record(
        self,
        employee_id: UUID,
        month: str,
        year: int,
        team_id: UUID
    ) -> None:
        """
        Invalidate performance record cache and related aggregations
        
        Invalidates:
        - Individual record cache
        - Team performance aggregation
        """
        keys_to_delete = [
            f"performance:{employee_id}:{month}:{year}",
            f"team_performance:{team_id}:{month}:{year}"
        ]
        
        for key in keys_to_delete:
            try:
                self.redis.delete(key)
            except redis.ConnectionError:
                logger.warning(f"Cache invalidation failed for key {key}")
    
    async def invalidate_team_config(self, team_id: UUID) -> None:
        """Invalidate team configuration cache across all instances"""
        cache_key = f"config:{team_id}:kpi_weights"
        
        # Delete local cache
        try:
            self.redis.delete(cache_key)
        except redis.ConnectionError:
            logger.warning(f"Cache invalidation failed for key {cache_key}")
        
        # Broadcast invalidation to other instances via message queue
        await message_queue.publish(
            "cache_invalidation",
            {
                "type": "team_config",
                "team_id": str(team_id),
                "timestamp": datetime.utcnow().isoformat()
            }
        )
```

### 4.2 In-Memory Session Cache

```python
class SessionCache:
    """
    In-memory cache for session data and configuration
    
    Strategy:
    - Session data: TTL 1 hour, size limit 1GB
    - KPI config: TTL 4 hours
    - LRU eviction when limit exceeded
    
    Preconditions:
    - Application memory available >= 1GB for session cache
    - TTL values configured for your needs
    
    Postconditions:
    - Session lookups < 1ms
    - Config data available for 4 hours
    """
    
    def __init__(self, max_memory_mb: int = 1024):
        self.cache = {}
        self.ttl_map = {}
        self.access_times = {}
        self.max_memory = max_memory_mb * 1024 * 1024
        self.current_size = 0
    
    async def get_session(self, user_id: UUID) -> Optional[SessionData]:
        """Get cached session data"""
        key = f"session:{user_id}"
        
        if key in self.cache:
            # Check TTL
            if self._is_expired(key):
                del self.cache[key]
                return None
            
            # Update access time for LRU
            self.access_times[key] = datetime.now()
            return self.cache[key]
        
        return None
    
    async def set_session(
        self,
        user_id: UUID,
        session_data: SessionData,
        ttl_seconds: int = 3600
    ) -> None:
        """Store session data with TTL"""
        key = f"session:{user_id}"
        
        # Estimate size and evict if necessary
        estimated_size = len(json.dumps(session_data.__dict__))
        if self.current_size + estimated_size > self.max_memory:
            self._evict_lru()
        
        self.cache[key] = session_data
        self.ttl_map[key] = datetime.now() + timedelta(seconds=ttl_seconds)
        self.access_times[key] = datetime.now()
        self.current_size += estimated_size
    
    def _is_expired(self, key: str) -> bool:
        """Check if cache entry has expired"""
        if key not in self.ttl_map:
            return False
        return datetime.now() > self.ttl_map[key]
    
    def _evict_lru(self) -> None:
        """Evict least-recently-used items to free memory"""
        if not self.cache:
            return
        
        # Find LRU entry
        lru_key = min(self.access_times.keys(), key=lambda k: self.access_times[k])
        
        # Remove it
        if lru_key in self.cache:
            size = len(json.dumps(self.cache[lru_key].__dict__))
            del self.cache[lru_key]
            del self.access_times[lru_key]
            if lru_key in self.ttl_map:
                del self.ttl_map[lru_key]
            self.current_size -= size
```


## 5. Batch Processing Engine

### 5.1 Batch Processing Architecture

```mermaid
graph LR
    Input["Input Data<br/>10K+ Records"]
    Validate["Validation<br/>Stage"]
    Process["Processing<br/>Chunks of 1000"]
    Transaction["Transaction<br/>Management"]
    Audit["Audit Logging<br/>Per Record"]
    Output["Results & Report"]
    
    Input --> Validate
    Validate --> Process
    Process --> Transaction
    Transaction --> Audit
    Audit --> Output
```

### 5.2 Batch Processor

```python
class BatchProcessor:
    """
    Processes large datasets efficiently with transaction management
    
    Characteristics:
    - Chunk size: 1000 records
    - Connection pool: 20 connections
    - Transaction mode: Atomic per batch
    - Error handling: Continue on error, log details
    - Audit: Create log entry per successful operation
    
    Preconditions:
    - All records validated before processing
    - Database connection pool available
    - Audit log table exists
    
    Postconditions:
    - All valid records inserted/updated atomically per chunk
    - Failed records logged with error details
    - Audit trail created for all successful operations
    - Processing completes in < 30 seconds for 10K records
    """
    
    def __init__(
        self,
        db_pool_size: int = 20,
        chunk_size: int = 1000,
        audit_enabled: bool = True
    ):
        self.db_pool_size = db_pool_size
        self.chunk_size = chunk_size
        self.audit_enabled = audit_enabled
        self.failed_records = []
        self.success_count = 0
    
    async def batch_insert_performance_records(
        self,
        records: List[dict],
        user_id: UUID,
        team_id: UUID
    ) -> BatchResult:
        """
        Insert multiple performance records in batches
        
        Process:
        1. Validate all records before insertion
        2. Chunk into groups of 1000
        3. Insert each chunk in single transaction
        4. Create audit log for each insert
        5. Return summary report
        
        Args:
            records: List of performance record dictionaries
            user_id: User performing the operation
            team_id: Team for these records
            
        Returns:
            BatchResult with success/failure counts
        """
        # Validate all records first
        validation_errors = await self._validate_records(records)
        if validation_errors:
            return BatchResult(
                status="failed",
                message="Validation failed",
                errors=validation_errors,
                success_count=0
            )
        
        # Process in chunks
        total_records = len(records)
        self.success_count = 0
        self.failed_records = []
        
        for chunk_idx in range(0, total_records, self.chunk_size):
            chunk = records[chunk_idx:chunk_idx + self.chunk_size]
            
            try:
                # Start transaction for this chunk
                async with db.begin():
                    for record in chunk:
                        try:
                            # Insert record
                            perf_record = PerformanceRecord(**record)
                            db.add(perf_record)
                            
                            # Create audit log
                            if self.audit_enabled:
                                audit_entry = AuditLog(
                                    table_name="performance_records",
                                    operation="INSERT",
                                    record_id=perf_record.id,
                                    new_values=record,
                                    performed_by_user_id=user_id
                                )
                                db.add(audit_entry)
                            
                            self.success_count += 1
                        except Exception as e:
                            self.failed_records.append({
                                "record": record,
                                "error": str(e),
                                "chunk": chunk_idx // self.chunk_size
                            })
            except Exception as e:
                # Transaction failed for entire chunk
                logger.error(f"Chunk {chunk_idx // self.chunk_size} failed: {str(e)}")
                for record in chunk:
                    self.failed_records.append({
                        "record": record,
                        "error": f"Chunk transaction failed: {str(e)}"
                    })
        
        return BatchResult(
            status="completed",
            message=f"Inserted {self.success_count} of {total_records} records",
            success_count=self.success_count,
            failed_count=len(self.failed_records),
            failed_records=self.failed_records[:100]  # Return first 100 errors
        )
    
    async def batch_update_kpi_weights(
        self,
        team_id: UUID,
        updates: List[dict],
        user_id: UUID
    ) -> BatchResult:
        """
        Update KPI weights for a team in single transaction
        
        Args:
            team_id: Team to update
            updates: List of {kpi_key, old_weight, new_weight}
            user_id: User performing update
            
        Returns:
            BatchResult with update counts
        """
        try:
            async with db.begin():
                for update in updates:
                    kpi_config = await db.query(TeamKPIConfig).filter(
                        (TeamKPIConfig.team_id == team_id) &
                        (TeamKPIConfig.kpi_key == update['kpi_key'])
                    ).first()
                    
                    if not kpi_config:
                        self.failed_records.append({
                            "kpi_key": update['kpi_key'],
                            "error": "KPI config not found"
                        })
                        continue
                    
                    old_weight = kpi_config.weight
                    kpi_config.weight = update['new_weight']
                    kpi_config.updated_by = user_id
                    
                    # Audit log
                    audit_entry = AuditLog(
                        table_name="team_kpi_config",
                        operation="UPDATE",
                        record_id=kpi_config.id,
                        old_values={"weight": str(old_weight)},
                        new_values={"weight": str(update['new_weight'])},
                        performed_by_user_id=user_id
                    )
                    db.add(audit_entry)
                    self.success_count += 1
            
            return BatchResult(
                status="completed",
                success_count=self.success_count,
                failed_count=len(self.failed_records)
            )
        except Exception as e:
            return BatchResult(
                status="failed",
                message=str(e),
                success_count=self.success_count
            )
    
    async def _validate_records(self, records: List[dict]) -> List[dict]:
        """
        Validate all records before processing
        
        Preconditions:
        - Each record has required fields
        
        Postconditions:
        - Returns list of validation errors (empty if valid)
        """
        errors = []
        for idx, record in enumerate(records):
            # Check required fields
            if not all(k in record for k in ['employee_id', 'month', 'year', 'score']):
                errors.append({
                    "record_index": idx,
                    "error": "Missing required fields"
                })
            
            # Validate field types and ranges
            if not isinstance(record.get('score'), (int, float)):
                errors.append({
                    "record_index": idx,
                    "error": "Score must be numeric"
                })
            
            if not (0 <= record.get('score', 0) <= 100):
                errors.append({
                    "record_index": idx,
                    "error": "Score must be between 0 and 100"
                })
        
        return errors

class BatchResult(BaseModel):
    """Result of batch operation"""
    status: str  # "completed", "failed"
    message: str = ""
    success_count: int = 0
    failed_count: int = 0
    errors: List[dict] = []
    failed_records: List[dict] = []
```


## 6. Audit & Versioning System

### 6.1 Audit Trail Architecture

```python
class AuditLog(Base):
    """Complete audit trail for all data modifications"""
    __tablename__ = "audit_log"
    
    id: UUID = Column(UUID(as_uuid=True), primary_key=True)
    table_name: str = Column(String(100), nullable=False)
    operation: str = Column(String(50), nullable=False)  # INSERT, UPDATE, DELETE, SOFT_DELETE
    record_id: UUID = Column(UUID(as_uuid=True), nullable=True)
    old_values: dict = Column(JSONB, nullable=True)  # JSON of old state
    new_values: dict = Column(JSONB, nullable=True)  # JSON of new state
    performed_by_user_id: UUID = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    performed_at: DateTime = Column(DateTime(timezone=True), server_default=func.now())
    ip_address: inet = Column(INET, nullable=True)  # Client IP
    request_id: str = Column(String(100), nullable=True)  # For request tracing

class AuditService:
    """
    Records all data changes for compliance and debugging
    
    Preconditions:
    - User is authenticated
    - Operation is on auditable table
    - Old and new values can be serialized to JSON
    
    Postconditions:
    - Audit log entry created for every operation
    - Entry includes user, timestamp, IP, and data changes
    - Logs queried for compliance reporting
    """
    
    async def log_operation(
        self,
        table_name: str,
        operation: str,
        record_id: UUID,
        old_values: dict = None,
        new_values: dict = None,
        user_id: UUID = None,
        ip_address: str = None,
        request_id: str = None
    ) -> AuditLog:
        """
        Create audit log entry
        
        Args:
            table_name: Table being modified (teams, employees, performance_records)
            operation: INSERT, UPDATE, DELETE, SOFT_DELETE
            record_id: ID of record being modified
            old_values: Previous state (for UPDATE/DELETE)
            new_values: New state (for INSERT/UPDATE)
            user_id: User performing operation
            ip_address: Client IP address
            request_id: Request tracking ID
            
        Returns:
            Created AuditLog entry
        """
        audit_entry = AuditLog(
            table_name=table_name,
            operation=operation,
            record_id=record_id,
            old_values=old_values,
            new_values=new_values,
            performed_by_user_id=user_id,
            ip_address=ip_address,
            request_id=request_id
        )
        
        db.add(audit_entry)
        await db.commit()
        await db.refresh(audit_entry)
        
        return audit_entry
    
    async def get_record_history(
        self,
        table_name: str,
        record_id: UUID
    ) -> List[AuditLog]:
        """
        Get all changes for a specific record in reverse chronological order
        
        Preconditions:
        - record_id exists or existed in specified table
        
        Postconditions:
        - Returns list of audit entries from newest to oldest
        """
        entries = await db.query(AuditLog).filter(
            (AuditLog.table_name == table_name) &
            (AuditLog.record_id == record_id)
        ).order_by(AuditLog.performed_at.desc()).all()
        
        return entries
    
    async def export_audit_logs(
        self,
        start_date: datetime,
        end_date: datetime,
        table_name: str = None
    ) -> str:
        """
        Export audit logs as CSV for compliance reporting
        
        Args:
            start_date: Start of date range
            end_date: End of date range
            table_name: Optional filter to specific table
            
        Returns:
            CSV formatted string
        """
        query = db.query(AuditLog).filter(
            (AuditLog.performed_at >= start_date) &
            (AuditLog.performed_at <= end_date)
        )
        
        if table_name:
            query = query.filter(AuditLog.table_name == table_name)
        
        entries = await query.all()
        
        # Convert to CSV
        csv_buffer = io.StringIO()
        writer = csv.DictWriter(csv_buffer, fieldnames=[
            'timestamp', 'table', 'operation', 'record_id', 
            'user_id', 'old_values', 'new_values', 'ip_address'
        ])
        writer.writeheader()
        
        for entry in entries:
            writer.writerow({
                'timestamp': entry.performed_at.isoformat(),
                'table': entry.table_name,
                'operation': entry.operation,
                'record_id': str(entry.record_id),
                'user_id': str(entry.performed_by_user_id),
                'old_values': json.dumps(entry.old_values) if entry.old_values else '',
                'new_values': json.dumps(entry.new_values) if entry.new_values else '',
                'ip_address': entry.ip_address
            })
        
        return csv_buffer.getvalue()

### 6.2 Soft Delete Implementation

class SoftDeleteService:
    """
    Implements soft deletes across all models
    
    Strategy:
    - Add is_active boolean (default=True) to auditable tables
    - DELETE operation sets is_active=False instead of removing rows
    - Queries filter is_active=True by default
    - Admin queries can include deleted records
    
    Preconditions:
    - is_active column exists on target table
    - Query filters include is_active check
    
    Postconditions:
    - No data permanently lost
    - Audit trail preserved
    - Query filters prevent accidental access to deleted records
    """
    
    async def soft_delete_employee(
        self,
        employee_id: UUID,
        user_id: UUID = None
    ) -> bool:
        """
        Soft delete employee record
        
        Sets is_active=False and creates audit log
        """
        employee = await db.query(Employee).filter(
            Employee.id == employee_id
        ).first()
        
        if not employee:
            return False
        
        old_state = {
            "id": str(employee.id),
            "is_active": employee.is_active
        }
        
        employee.is_active = False
        await db.commit()
        
        # Audit log
        await audit_service.log_operation(
            table_name="employees",
            operation="SOFT_DELETE",
            record_id=employee_id,
            old_values=old_state,
            new_values={"is_active": False},
            user_id=user_id
        )
        
        return True
    
    async def restore_employee(
        self,
        employee_id: UUID,
        user_id: UUID = None
    ) -> bool:
        """Restore soft-deleted employee"""
        employee = await db.query(Employee).filter(
            (Employee.id == employee_id) &
            (Employee.is_active == False)
        ).first()
        
        if not employee:
            return False
        
        employee.is_active = True
        await db.commit()
        
        # Audit log
        await audit_service.log_operation(
            table_name="employees",
            operation="RESTORE",
            record_id=employee_id,
            old_values={"is_active": False},
            new_values={"is_active": True},
            user_id=user_id
        )
        
        return True

### 6.3 Data Versioning System

class PerformanceRecordVersion(Base):
    """Historical snapshot of performance record changes"""
    __tablename__ = "performance_record_versions"
    
    id: UUID = Column(UUID(as_uuid=True), primary_key=True)
    original_record_id: UUID = Column(UUID(as_uuid=True), nullable=False)
    version_number: int = Column(Integer, nullable=False)
    score: Numeric = Column(Numeric(6, 2), nullable=False)
    grade: str = Column(String(5), nullable=False)
    status: str = Column(String(20), nullable=False)
    changed_by_user_id: UUID = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    changed_at: DateTime = Column(DateTime(timezone=True), server_default=func.now())
    change_reason: str = Column(Text, nullable=True)

class VersioningService:
    """
    Maintains historical versions of key entities
    
    Preconditions:
    - Version table exists for entity type
    - Change reason provided for all updates
    
    Postconditions:
    - Complete history available
    - Can reconstruct entity state at any point in time
    - Data analysis and discrepancy investigation enabled
    """
    
    async def create_version(
        self,
        record_id: UUID,
        old_values: dict,
        new_values: dict,
        change_reason: str,
        user_id: UUID
    ) -> PerformanceRecordVersion:
        """Create version snapshot on update"""
        # Get latest version number
        latest = await db.query(
            func.max(PerformanceRecordVersion.version_number)
        ).filter(
            PerformanceRecordVersion.original_record_id == record_id
        ).scalar()
        
        version_number = (latest or 0) + 1
        
        version = PerformanceRecordVersion(
            original_record_id=record_id,
            version_number=version_number,
            score=new_values.get('score'),
            grade=new_values.get('grade'),
            status=new_values.get('status'),
            changed_by_user_id=user_id,
            change_reason=change_reason
        )
        
        db.add(version)
        await db.commit()
        
        return version
    
    async def get_version_history(
        self,
        record_id: UUID
    ) -> List[PerformanceRecordVersion]:
        """Get complete version history for a record"""
        versions = await db.query(PerformanceRecordVersion).filter(
            PerformanceRecordVersion.original_record_id == record_id
        ).order_by(PerformanceRecordVersion.changed_at).all()
        
        return versions
    
    async def get_record_as_of_date(
        self,
        record_id: UUID,
        as_of_date: datetime
    ) -> dict:
        """Reconstruct record state as it existed on specific date"""
        version = await db.query(PerformanceRecordVersion).filter(
            (PerformanceRecordVersion.original_record_id == record_id) &
            (PerformanceRecordVersion.changed_at <= as_of_date)
        ).order_by(
            PerformanceRecordVersion.version_number.desc()
        ).first()
        
        if not version:
            # Record didn't exist on this date
            return None
        
        return {
            "score": float(version.score),
            "grade": version.grade,
            "status": version.status,
            "as_of_date": as_of_date,
            "version": version.version_number
        }
```


## 7. Monitoring & Health Checks

### 7.1 Health Check System

```python
class HealthCheckService:
    """
    Monitors system availability and component health
    
    Components checked:
    - Database connectivity
    - Redis cache connectivity
    - API service responsiveness
    
    Response times:
    - Health check endpoint < 100ms
    - Individual component checks < 50ms
    
    Preconditions:
    - Database connection pool configured
    - Redis client configured
    - Health check status cached
    
    Postconditions:
    - HTTP 200 if all components healthy
    - HTTP 503 if critical component unavailable
    - HTTP 200 (degraded) if optional component unavailable
    - Response includes component details and timestamps
    """
    
    def __init__(self, cache_ttl_seconds: int = 10):
        self.cache_ttl = cache_ttl_seconds
        self.last_check = None
        self.last_result = None
    
    async def check_health(self) -> dict:
        """
        Perform health check on all components
        
        Returns:
        {
            "status": "healthy|degraded|unhealthy",
            "timestamp": "2024-01-15T10:30:00Z",
            "components": {
                "database": {"status": "up", "response_time_ms": 12},
                "cache": {"status": "up", "response_time_ms": 5},
                "api": {"status": "up", "response_time_ms": 2}
            },
            "overall_response_time_ms": 19
        }
        """
        start_time = time.time()
        
        # Check cache first
        cache_key = "health_check:status"
        cached = await cache.get(cache_key)
        if cached:
            return cached
        
        components = {}
        overall_status = "healthy"
        
        # Check database
        db_start = time.time()
        try:
            result = await db.execute("SELECT 1")
            db_time = (time.time() - db_start) * 1000
            components["database"] = {
                "status": "up",
                "response_time_ms": round(db_time, 2)
            }
        except Exception as e:
            components["database"] = {
                "status": "down",
                "error": str(e)
            }
            overall_status = "unhealthy"
        
        # Check cache
        cache_start = time.time()
        try:
            await cache.get("health_check:ping")
            cache_time = (time.time() - cache_start) * 1000
            components["cache"] = {
                "status": "up",
                "response_time_ms": round(cache_time, 2)
            }
        except Exception as e:
            components["cache"] = {
                "status": "down",
                "error": str(e)
            }
            # Cache being down is degraded, not unhealthy
            if overall_status == "healthy":
                overall_status = "degraded"
        
        # Compile response
        total_time = (time.time() - start_time) * 1000
        result = {
            "status": overall_status,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "components": components,
            "overall_response_time_ms": round(total_time, 2)
        }
        
        # Cache result
        await cache.set(cache_key, result, ex=self.cache_ttl)
        
        return result
    
    async def get_health_status(self) -> int:
        """
        Get HTTP status code for health check
        
        Returns:
        - 200: All components healthy or degraded (cache down)
        - 503: Critical component down (database)
        """
        health = await self.check_health()
        
        if health["components"]["database"]["status"] != "up":
            return 503
        
        return 200
```

### 7.2 Error Tracking System

```python
class ErrorLog(Base):
    """Error tracking and alerting"""
    __tablename__ = "error_logs"
    
    id: UUID = Column(UUID(as_uuid=True), primary_key=True)
    error_type: str = Column(String(100), nullable=False)
    message: str = Column(Text, nullable=False)
    stack_trace: str = Column(Text, nullable=True)
    endpoint: str = Column(String(255), nullable=True)
    method: str = Column(String(10), nullable=True)  # GET, POST, etc
    user_id: UUID = Column(UUID(as_uuid=True), nullable=True)
    request_id: str = Column(String(100), nullable=True)
    context: dict = Column(JSONB, nullable=True)
    occurred_at: DateTime = Column(DateTime(timezone=True), server_default=func.now())
    severity: str = Column(String(20), default="error")  # info, warning, error, critical

class ErrorTracker:
    """
    Captures and tracks application errors
    
    Preconditions:
    - Error occurs during request processing
    - Request context available (user_id, IP, endpoint)
    
    Postconditions:
    - Error logged to database
    - Alert triggered if error rate threshold exceeded
    - Error aggregation available for monitoring
    """
    
    async def log_error(
        self,
        error: Exception,
        endpoint: str = None,
        method: str = None,
        user_id: UUID = None,
        request_id: str = None,
        severity: str = "error"
    ) -> ErrorLog:
        """
        Log application error
        
        Args:
            error: Exception that occurred
            endpoint: API endpoint that was called
            method: HTTP method (GET, POST, etc)
            user_id: User who triggered error
            request_id: Request tracking ID
            severity: error severity (info, warning, error, critical)
            
        Returns:
            ErrorLog entry
        """
        import traceback
        
        error_entry = ErrorLog(
            error_type=type(error).__name__,
            message=str(error),
            stack_trace=traceback.format_exc(),
            endpoint=endpoint,
            method=method,
            user_id=user_id,
            request_id=request_id,
            severity=severity,
            context={
                "timestamp": datetime.utcnow().isoformat()
            }
        )
        
        db.add(error_entry)
        await db.commit()
        
        # Check if alert needed
        await self._check_alert_threshold()
        
        return error_entry
    
    async def _check_alert_threshold(self):
        """
        Check if error rate exceeds threshold (1% of requests)
        
        Preconditions:
        - request_metrics table tracks total requests
        - Alert threshold set to 1%
        
        Postconditions:
        - Send alert if threshold exceeded
        """
        # Get error count in last 5 minutes
        five_min_ago = datetime.utcnow() - timedelta(minutes=5)
        error_count = await db.query(func.count(ErrorLog.id)).filter(
            ErrorLog.occurred_at >= five_min_ago
        ).scalar()
        
        # Get request count in last 5 minutes
        request_count = await db.query(func.count(RequestMetric.id)).filter(
            RequestMetric.timestamp >= five_min_ago
        ).scalar()
        
        if request_count > 0:
            error_rate = error_count / request_count
            if error_rate > 0.01:  # 1% threshold
                await alert_service.send_alert(
                    title="High Error Rate",
                    message=f"Error rate {error_rate*100:.2f}% exceeds threshold",
                    severity="critical"
                )

class AlertService:
    """
    Sends alerts for critical system events
    
    Preconditions:
    - Alert channels configured (email, Slack)
    - Alert rules defined
    
    Postconditions:
    - Alert delivered to ops team
    - Alert logged for audit trail
    """
    
    async def send_alert(
        self,
        title: str,
        message: str,
        severity: str = "warning",
        channel: str = None
    ):
        """
        Send alert to configured channels
        
        Channels:
        - email: ops team email
        - slack: #alerts Slack channel
        """
        # Log alert
        logger.error(f"[{severity.upper()}] {title}: {message}")
        
        # Send to Slack if configured
        if channel != "email" and slack_webhook:
            await self._send_slack_alert(title, message, severity)
        
        # Send to email if configured
        if channel != "slack" and email_config:
            await self._send_email_alert(title, message, severity)
    
    async def _send_slack_alert(self, title: str, message: str, severity: str):
        """Send alert to Slack"""
        color_map = {
            "info": "#36a64f",
            "warning": "#ff9900",
            "critical": "#ff0000"
        }
        
        payload = {
            "attachments": [{
                "title": title,
                "text": message,
                "color": color_map.get(severity, "#888888"),
                "footer": "PMS Dashboard Monitoring",
                "ts": int(time.time())
            }]
        }
        
        async with aiohttp.ClientSession() as session:
            await session.post(slack_webhook, json=payload)
    
    async def _send_email_alert(self, title: str, message: str, severity: str):
        """Send alert via email"""
        # Implementation using email service
        pass
```


## 8. Deployment Pipeline

### 8.1 Docker Containerization

```dockerfile
# Dockerfile - Backend Application Container
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV APP_HOME=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR $APP_HOME

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser $APP_HOME

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/health')"

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 8.2 CI/CD Pipeline Configuration

```yaml
# .github/workflows/deploy.yml - GitHub Actions Pipeline
name: PMS Dashboard Deployment Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/pms-backend

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=semver,pattern={{version}}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: ./Backend
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
  
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: pms_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          cd Backend
          pip install -r requirements.txt
          pip install pytest pytest-asyncio pytest-cov
      
      - name: Run linting
        run: |
          cd Backend
          pip install flake8
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
      
      - name: Run tests
        run: |
          cd Backend
          pytest tests/ -v --cov=. --cov-report=xml
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/pms_test
          REDIS_URL: redis://localhost:6379
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./Backend/coverage.xml
  
  deploy-staging:
    needs: [build, test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Staging
        run: |
          # Deploy logic here
          # Example: kubectl apply -f k8s/staging/
          echo "Deploying to staging..."
  
  deploy-production:
    needs: [build, test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    environment:
      name: production
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Production
        run: |
          # Production deployment
          echo "Deploying to production..."
      
      - name: Verify Deployment
        run: |
          # Health checks
          echo "Verifying deployment..."
      
      - name: Rollback on Failure
        if: failure()
        run: |
          # Rollback to previous version
          echo "Rolling back to previous version..."
```

### 8.3 Kubernetes Deployment

```yaml
# k8s/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pms-backend
  labels:
    app: pms-backend
spec:
  replicas: 3  # Horizontal scaling
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: pms-backend
  template:
    metadata:
      labels:
        app: pms-backend
    spec:
      containers:
      - name: pms-backend
        image: ghcr.io/yourorg/pms-backend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: pms-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: pms-secrets
              key: redis-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: pms-secrets
              key: jwt-secret
        - name: ENVIRONMENT
          value: "production"
        
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        
        livenessProbe:
          httpGet:
            path: /api/health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /api/health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL

---
apiVersion: v1
kind: Service
metadata:
  name: pms-backend-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
    name: http
  selector:
    app: pms-backend

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: pms-backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: pms-backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 8.4 Docker Compose Configuration

```yaml
# docker-compose.yml - Single-host deployment
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: pms_db
    environment:
      POSTGRES_USER: pms_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: pms_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pms_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: pms_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./Backend
      dockerfile: Dockerfile
    container_name: pms_backend
    environment:
      DATABASE_URL: postgresql://pms_user:${DB_PASSWORD}@db:5432/pms_db
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET}
      ENVIRONMENT: ${ENVIRONMENT:-development}
    ports:
      - "8000:8000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./Backend:/app
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: pms_network
```


## 9. Integration Flows

### 9.1 End-to-End Request Flow

```mermaid
sequenceDiagram
    participant Client as Client
    participant Gateway as API Gateway
    participant Auth as Auth Middleware
    participant RBAC as RBAC Middleware
    participant Service as Service Layer
    participant DB as PostgreSQL
    participant Cache as Redis Cache
    participant Audit as Audit Service
    
    Client->>Gateway: POST /api/performance/bulk
    Gateway->>Auth: Validate JWT Token
    Auth->>Auth: Verify signature & expiration
    Auth->>Gateway: Token valid
    
    Gateway->>RBAC: Check permission (upload_data)
    RBAC->>RBAC: Verify user has permission
    RBAC->>Gateway: Permission granted
    
    Gateway->>Service: Process batch upload
    Service->>Service: Validate all records
    Service->>Service: Split into chunks of 1000
    
    loop For each chunk
        Service->>DB: BEGIN TRANSACTION
        Service->>DB: Insert batch of 1000 records
        Service->>Audit: Log INSERT operations
        Service->>DB: COMMIT TRANSACTION
        Service->>Cache: Invalidate related cache
    end
    
    Service->>Client: Return BatchResult
    Client->>Client: Display results
```

### 9.2 Performance Data Query Flow with Caching

```mermaid
sequenceDiagram
    participant Client as Client
    participant Service as Performance Service
    participant Cache as Redis Cache
    participant DB as PostgreSQL
    participant OptDB as Index Optimizer
    
    Client->>Service: GET /api/performance/{emp_id}?month=01&year=2024
    
    Service->>Cache: Check cache key
    alt Cache HIT
        Cache-->>Service: Return cached data
        Service-->>Client: HTTP 200 {data}
    else Cache MISS
        Service->>DB: Query with indexed columns
        OptDB->>OptDB: Use composite index (emp_id, month, year)
        DB->>DB: Fetch + eager load kpi_values
        DB-->>Service: Performance records
        
        Service->>Cache: Store in cache (1hr TTL)
        Service-->>Client: HTTP 200 {data}
    end
```

### 9.3 Authentication & Authorization Flow

```
┌────────────────────────────────────────────────────────────┐
│                    Authentication Flow                     │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Client POST /login (username, password)                │
│  ↓                                                          │
│  2. AuthService.authenticate_user()                        │
│     ├─ Query database: users.find(username)               │
│     ├─ Verify: bcrypt.compare(password, hash)             │
│     ├─ Update: users.last_login = now()                   │
│     └─ Generate: JWT(user_id, role, exp=now+1hr)          │
│  ↓                                                          │
│  3. Return JWT token + user profile                        │
│  ├─ Store token in client (localStorage/cookie)           │
│  └─ Store session in Redis (user_id → SessionData)        │
│  ↓                                                          │
│  4. Subsequent requests include: Authorization: Bearer {token}
│  ↓                                                          │
│  5. AuthMiddleware.validate_token()                        │
│     ├─ Parse JWT: jwt.decode(token, secret)              │
│     ├─ Validate: signature, expiration                    │
│     ├─ Refresh: session last_activity timestamp           │
│     └─ Allow: continue to route handler                   │
│  ↓                                                          │
│  6. RBACMiddleware.check_permission()                      │
│     ├─ Get session from cache: session:{user_id}          │
│     ├─ Check: user.role in allowed_roles                  │
│     ├─ Verify: user.permissions includes required         │
│     ├─ If team-scoped: check team_assignments             │
│     └─ Allow/Deny: based on permissions                   │
│  ↓                                                          │
│  7. Route handler executes                                 │
│  └─ Full request context available (user_id, role, etc)   │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### 9.4 Data Modification Audit Trail

```
┌────────────────────────────────────────────────────────────┐
│              Data Modification & Audit Flow                │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  User: POST /api/performance/{id} (update score)          │
│  ↓                                                          │
│  1. Request validated and authorized                       │
│  ↓                                                          │
│  2. PerformanceService.update_performance_record()        │
│     ├─ Get old record: query database                     │
│     ├─ Apply changes: new score = 92                      │
│     ├─ Save: db.commit()                                  │
│     └─ Capture: old_values, new_values for audit         │
│  ↓                                                          │
│  3. AuditService.log_operation()                          │
│     ├─ table_name: "performance_records"                  │
│     ├─ operation: "UPDATE"                                │
│     ├─ old_values: {score: 85, grade: B}                 │
│     ├─ new_values: {score: 92, grade: A}                 │
│     ├─ performed_by_user_id: {user_id}                    │
│     ├─ ip_address: {client_ip}                            │
│     └─ performed_at: now()                                │
│  ↓                                                          │
│  4. VersioningService.create_version()                    │
│     ├─ Get version_number: max + 1                        │
│     ├─ Store snapshot: performance_record_versions        │
│     ├─ change_reason: provided by user                    │
│     └─ changed_by_user_id: {user_id}                      │
│  ↓                                                          │
│  5. CacheInvalidationService.invalidate_performance_record()
│     ├─ Delete: "performance:{emp_id}:{month}:{year}"     │
│     ├─ Delete: "team_performance:{team_id}:{month}:{year}"
│     └─ Publish: cache_invalidation event                 │
│  ↓                                                          │
│  6. Return 200 {updated_record}                           │
│                                                             │
│  Result: Complete audit trail with who, what, when, where │
│  Can reconstruct data to any point in time                │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## 10. Error Handling & Recovery

### 10.1 Error Handling Patterns

```python
class ErrorHandlingMiddleware:
    """
    Global error handling for all exceptions
    
    Preconditions:
    - Exception occurs in route handler
    - Request context available (user_id, endpoint, IP)
    
    Postconditions:
    - Exception logged with context
    - User-friendly error response returned
    - Alert triggered if severity warrants
    """
    
    async def __call__(self, request: Request, call_next):
        try:
            response = await call_next(request)
            return response
        except HTTPException as e:
            # Expected HTTP errors (auth, validation, etc)
            await error_tracker.log_error(
                e,
                endpoint=request.url.path,
                method=request.method,
                severity="warning"
            )
            return JSONResponse(
                status_code=e.status_code,
                content={"detail": e.detail}
            )
        except ValueError as e:
            # Validation/business logic errors
            await error_tracker.log_error(
                e,
                endpoint=request.url.path,
                method=request.method,
                severity="warning"
            )
            return JSONResponse(
                status_code=400,
                content={"detail": str(e)}
            )
        except Exception as e:
            # Unexpected errors - critical
            await error_tracker.log_error(
                e,
                endpoint=request.url.path,
                method=request.method,
                severity="critical"
            )
            return JSONResponse(
                status_code=500,
                content={"detail": "Internal server error"}
            )

### 10.2 Cache Fallback Strategy

class CacheFallbackStrategy:
    """
    Handles cache unavailability gracefully
    
    Strategy:
    - If cache available: use cached result
    - If cache down: query database directly
    - If database down: return error
    - Never return stale data from fallback
    """
    
    async def get_with_fallback(self, query_func, cache_key, ttl=3600):
        """
        Get data with automatic fallback from cache to database
        """
        # Try cache first
        try:
            cached = await cache.get(cache_key)
            if cached:
                return cached
        except redis.ConnectionError:
            logger.warning("Cache unavailable, falling back to database")
        
        # Cache miss or unavailable - query database
        try:
            result = await query_func()
            
            # Try to cache result for future requests
            try:
                await cache.set(cache_key, result, ex=ttl)
            except redis.ConnectionError:
                # Warn but don't fail
                logger.warning(f"Could not cache result for {cache_key}")
            
            return result
        except Exception as e:
            logger.error(f"Database query failed: {str(e)}")
            raise

### 10.3 Batch Operation Rollback

class BatchRollbackStrategy:
    """
    Implements atomic transactions for batch operations
    
    Strategy:
    - Process all records in single transaction
    - If any record fails: rollback entire batch
    - Return detailed error report
    """
    
    async def execute_batch_with_rollback(self, operations):
        """
        Execute batch operations atomically
        
        If any operation fails:
        - Rollback all changes in transaction
        - Return which record caused failure
        - User can fix and retry
        """
        try:
            async with db.begin():
                for idx, op in enumerate(operations):
                    try:
                        result = await self._execute_operation(op)
                    except Exception as e:
                        # Raise to trigger rollback
                        raise ValueError(f"Operation {idx} failed: {str(e)}")
            
            return {"status": "success", "operations": len(operations)}
        except Exception as e:
            # Transaction rolled back automatically
            return {
                "status": "failed",
                "error": str(e),
                "operations_committed": 0
            }
```

## 11. Correctness Properties

These properties must be satisfied for the system to operate correctly:

### Authentication Properties

- **P1**: ∀ user, password: authenticate_user(user, password) → JWT_Token
  - If credentials valid: returns JWT token with 1-hour expiration
  - Token can be decoded and verified with secret key
  
- **P2**: ∀ token: validate_token(token) → Boolean
  - If token valid and not expired: returns True
  - If token invalid or expired: returns False or throws HTTPException(401)

- **P3**: ∀ user, password: password_hash is never stored in plaintext
  - Password stored as bcrypt hash with 12+ salt rounds
  - Plaintext password never logged or cached

### Authorization Properties

- **P4**: ∀ user, permission: check_permission(user, permission) is consistent
  - Admin users always permitted (all operations)
  - Manager users permitted only for assigned teams
  - Viewer users only permitted to read (no write operations)

- **P5**: ∀ team_assignment removed: user loses immediate access
  - Permission check returns False immediately after removal
  - Cache invalidated across all instances

### Database Properties

- **P6**: ∀ query on indexed column: execution_time < 10ms for indexed columns
  - Composite index (employee_id, month, year) used for performance queries
  - Query planner uses index scan, not sequential scan

- **P7**: ∀ pagination with limit N: returns exactly N results or fewer
  - Page size capped at 100 records
  - Results sorted consistently

### Caching Properties

- **P8**: ∀ cache entry with TTL T: entry removed after T seconds
  - Cache entries expire after specified TTL
  - Expired entries not returned to client

- **P9**: ∀ write operation: related cache entries invalidated
  - When record updated: single-record cache invalidated
  - When record updated: team aggregation cache invalidated

### Audit Trail Properties

- **P10**: ∀ data modification: audit log entry created
  - Every INSERT, UPDATE, DELETE, SOFT_DELETE creates log entry
  - Log includes user_id, timestamp, old_values, new_values

- **P11**: ∀ audit log query: returns entries in reverse chronological order
  - Most recent changes returned first
  - Complete history available for compliance

### Batch Properties

- **P12**: ∀ batch operation: all-or-nothing atomicity
  - Entire batch committed as single transaction
  - If any record fails: entire batch rolled back

- **P13**: ∀ batch with N records in chunks of C: ⌈N/C⌉ transactions
  - Batch split into chunks of 1000 records max
  - Each chunk processed in separate transaction

### Health Check Properties

- **P14**: ∀ health check: response_time < 100ms
  - Health check completes quickly
  - Load balancer can use for availability detection

- **P15**: ∀ component unavailable: appropriate HTTP status returned
  - Database down: HTTP 503 Service Unavailable
  - Cache down: HTTP 200 Degraded (system still works)


## 12. Implementation Considerations

### 12.1 Security Considerations

**Password Security**:
- Use bcrypt with minimum 12 salt rounds
- Enforce password complexity: 12+ chars, uppercase, lowercase, digit, special char
- Implement account lockout: 5 failed attempts → 15 minute lock
- Track password history and prevent reuse of last 5 passwords

**Token Security**:
- JWT tokens expire after 1 hour (not stored in database)
- Include token signature verification on every request
- Implement token refresh mechanism for long-running sessions
- Store JWT secret in environment, never in code

**Database Security**:
- Use parameterized queries to prevent SQL injection
- Encrypt sensitive columns (password_hash, social_security_number)
- Implement row-level security for multi-tenant scenarios
- Regular backups with encryption at rest

**API Security**:
- HTTPS only (TLS 1.2+)
- CORS configured to allow only authorized origins
- Rate limiting: 100 requests/minute per IP
- Input validation on all endpoints
- SQL injection prevention via ORM parameterization

### 12.2 Performance Considerations

**Database Tuning**:
- Create composite indexes on frequently filtered columns
- Monitor slow queries (> 100ms) using pg_stat_statements
- Partition performance_records by year for large datasets
- Regular ANALYZE and VACUUM operations

**Caching Strategy**:
- Cache time-series data with 1-hour TTL
- Invalidate cache on write operations
- Monitor cache hit ratio (target: 80%+)
- Set Redis max memory to 500MB with LRU eviction

**Query Optimization**:
- Use eager loading to prevent N+1 queries
- Limit result sets to 100 records per page
- Implement connection pooling (pool_size=20)
- Monitor query execution plans with EXPLAIN

**Batch Processing**:
- Process in chunks of 1000 records
- Use database transactions for atomicity
- Monitor batch duration (target: < 30 seconds for 10K records)
- Implement progress reporting for large imports

### 12.3 Scalability Considerations

**Horizontal Scaling**:
- Stateless API servers (session data in Redis, not memory)
- Load balancer distributes requests across multiple instances
- Database connection pooling shared across instances
- Cache synchronization via message queue for multi-instance deployments

**Vertical Scaling**:
- Allocate 1GB for in-memory session cache per instance
- Monitor CPU usage (target: 70-80% utilization)
- Monitor memory usage (target: 80% utilization max)
- Configure auto-scaling in Kubernetes based on metrics

**Database Scaling**:
- Read replicas for reporting queries
- Connection pooling with pgBouncer for high concurrency
- Partitioning for large tables (performance_records by year)
- Archival of old records to separate database

### 12.4 Monitoring and Observability

**Metrics to Track**:
- Request latency (p50, p95, p99)
- Error rate (% of requests)
- Cache hit ratio
- Database connection pool utilization
- Memory usage per instance
- CPU utilization per instance

**Logging Strategy**:
- Structured JSON logging for all events
- Log levels: INFO (requests), WARN (timeouts), ERROR (failures)
- Include request_id for tracing through system
- Centralized log aggregation (ELK, Datadog, CloudWatch)

**Alerting Thresholds**:
- Error rate > 1% over 5 minutes: critical alert
- Response time p95 > 1 second: warning alert
- Database connection pool > 90% utilized: warning
- Memory usage > 80%: warning alert
- Cache unavailable: degraded alert (not critical)

### 12.5 Testing Strategy

**Unit Tests**:
- Test each service method independently
- Mock external dependencies (database, cache, email)
- Target: 80%+ code coverage
- Test both happy path and error cases

**Integration Tests**:
- Test complete request/response flows
- Use test database and Redis instances
- Verify database state after operations
- Test cache invalidation patterns

**Property-Based Tests** (using fast-check, hypothesis):
- Verify invariants hold for random inputs
- Test authentication properties: all passwords produce valid hashes
- Test authorization properties: permission checks consistent
- Test batch operations: atomicity preserved

**Load Testing**:
- Simulate 100 concurrent users
- Target: p95 response time < 500ms
- Monitor cache hit ratio under load
- Verify batch processing completes in < 30 seconds

**Security Testing**:
- Test SQL injection prevention
- Test authentication bypass attempts
- Test CSRF token validation
- Verify sensitive data not in logs

### 12.6 Deployment Checklist

**Pre-Deployment**:
- [ ] All tests passing (unit, integration, load)
- [ ] Code review completed
- [ ] Security scan passed
- [ ] Database migration tested
- [ ] Environment variables configured
- [ ] Secrets stored in secure vault
- [ ] Rollback plan documented

**Deployment Steps**:
1. [ ] Build Docker image with commit SHA tag
2. [ ] Push image to registry
3. [ ] Run integration tests with new image
4. [ ] Update Kubernetes manifests or docker-compose
5. [ ] Deploy to staging environment
6. [ ] Run smoke tests in staging
7. [ ] Deploy to production (blue-green or canary)
8. [ ] Monitor error rate and latency
9. [ ] Verify health check endpoints
10. [ ] Confirm audit logs recording

**Post-Deployment**:
- [ ] Monitor error rate (target: < 0.1%)
- [ ] Monitor latency (p95 < 500ms)
- [ ] Verify cache hit ratio (target: > 80%)
- [ ] Check log aggregation working
- [ ] Confirm alerts configured
- [ ] Document lessons learned
- [ ] Plan next deployment window

---

## 13. Summary

This design provides a comprehensive, enterprise-grade architecture for the PMS Dashboard with:

✅ **Security**: JWT authentication, bcrypt hashing, role-based access control, audit trails  
✅ **Performance**: Redis caching, query optimization, batch processing, connection pooling  
✅ **Reliability**: Health checks, error tracking, alerting, graceful degradation  
✅ **Compliance**: Complete audit trails, soft deletes, data versioning, compliance exports  
✅ **Scalability**: Horizontal scaling with Kubernetes, caching, connection pooling  
✅ **Observability**: Structured logging, metrics, health endpoints, error tracking  
✅ **Deployment**: Docker containerization, CI/CD pipelines, rollback capabilities  

All components are designed for high availability, performance, and maintainability in a production environment.
