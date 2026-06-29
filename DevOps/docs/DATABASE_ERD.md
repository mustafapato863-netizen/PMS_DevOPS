# Database Entity-Relationship Diagram (ERD)

This document provides a detailed visual map of the database schemas, table schemas, and relational constraints within the PMS Dashboard.

---

## 1. Database Entity-Relationship Diagram

The Mermaid diagram below shows the schema tables and their relationships:

```mermaid
erDiagram
    users {
        uuid id PK
        varchar username UK
        varchar email UK
        text password_hash
        user_role role
        boolean is_active
        timestamptz last_login
    }

    role_permissions {
        uuid id PK
        varchar role
        varchar permission
    }

    teams {
        uuid id PK
        varchar name UK
        varchar db_name UK
        varchar region
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    user_team_assignments {
        uuid id PK
        uuid user_id FK
        uuid team_id FK
        access_level access_level
        timestamptz assigned_at
    }

    employees {
        uuid id PK
        varchar employee_id UK
        varchar name
        uuid team_id FK
        varchar region
        boolean is_active
    }

    upload_log {
        uuid id PK
        uuid team_id FK
        varchar month
        smallint year
        integer record_count
        uuid uploaded_by_user_id FK
        upload_status status
        text error_message
        timestamptz uploaded_at
    }

    performance_records {
        uuid id PK
        uuid employee_id FK
        uuid team_id FK
        varchar month
        smallint year PK "Composite Key"
        numeric score
        grade_class grade
        perf_status status
        uuid upload_id FK
        timestamptz uploaded_at
    }

    kpi_values {
        uuid id PK
        uuid record_id FK
        smallint record_year FK "Composite FK"
        varchar kpi_key
        numeric actual_value
        numeric target_value
        numeric achievement_ratio
        numeric weight_applied
        numeric contribution
    }

    kpi_weight_history {
        uuid id PK
        uuid team_id FK
        varchar kpi_key
        numeric old_weight
        numeric new_weight
        timestamptz changed_at
        varchar changed_by
        text reason
    }

    grade_thresholds {
        uuid id PK
        uuid team_id FK "UK"
        numeric grade_a
        numeric grade_b
        numeric grade_c
        numeric grade_d
    }

    actions {
        uuid id PK
        uuid employee_id FK
        uuid team_id FK
        varchar month
        smallint year
        action_type action_type
        text action_text
        text root_cause_note
        action_status status
        uuid created_by_user_id FK
        timestamptz created_at
    }

    notifications {
        uuid id PK
        notif_type type
        varchar title
        text message
        varchar room
        jsonb payload
        timestamptz created_at
    }

    notification_recipients {
        uuid id PK
        uuid notification_id FK
        uuid user_id FK
        boolean is_read
        timestamptz read_at
    }

    audit_log {
        uuid id PK
        varchar table_name
        audit_op operation
        uuid record_id
        jsonb old_values
        jsonb new_values
        uuid performed_by_user_id FK
        timestamptz performed_at
        inet ip_address
    }

    users ||--o{ user_team_assignments : "assigned"
    teams ||--o{ user_team_assignments : "assigned"
    teams ||--o{ employees : "belongs to"
    teams ||--o{ upload_log : "ingested for"
    users ||--o{ upload_log : "uploaded by"
    employees ||--o{ performance_records : "scores"
    teams ||--o{ performance_records : "belongs to"
    upload_log ||--o{ performance_records : "populates"
    performance_records ||--o{ kpi_values : "contains"
    teams ||--o{ kpi_weight_history : "tracks"
    teams ||--o| grade_thresholds : "defines"
    employees ||--o{ actions : "receives"
    teams ||--o{ actions : "scoped to"
    users ||--o{ actions : "created by"
    notifications ||--o{ notification_recipients : "notifies"
    users ||--o{ notification_recipients : "notifies"
    users ||--o{ audit_log : "mutates"
