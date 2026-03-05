# Compliance Tracker - User Manual

Welcome to the Compliance Tracker Platform! This manual will guide you through the core features of the system, tailored for Administrators, Compliance Managers, and general Stakeholders.

---

## 1. Getting Started & Navigation

When you log into the platform, you are placed into your **Organization's Tenant**. All data, from compliance frameworks to documents and user roles, is strictly isolated to your organization.

### The Main Navigation
- **Dashboard:** Your central hub. Shows a high-level overview of active workflows, upcoming tasks, and compliance implementation progress.
- **Documents:** Access your Organization's central document repository (Policies, Procedures, etc.).
- **Compliance:** The core modules. Access Frameworks, Controls, Risks, and your specific implementation progress.
- **Providers:** An index of regulatory bodies or service providers providing regulatory requirements.
- **My Tasks:** A Kanban-style board showing specific compliance actions assigned to you (To Do, In Progress, Done).
- **My Reviews:** (For Stakeholders) View newly acquired regulations that have been assigned to you for review, classification, or decision-making.
- **Admin (Super Admins Only):** Global settings, Data Source connections, and Webhook trace monitoring.

---

## 2. Managing Compliance Frameworks

A **Compliance Framework** (e.g., SOC 2, ISO 27001, HIPAA) is a collection of requirements your organization must meet.

1. Navigate to **Compliance > Frameworks**.
2. Click **New Framework** to create a custom framework, or adopt an existing industry standard.
3. Once created, click into the Framework to define its **Compliance Requirements**.
4. **Breaking down Regulations:** If a new Regulation (e.g., CCPA) mandates changes, click "Breakdown Regulation" to use AI to automatically suggest and map technical requirements directly to your Framework.

---

## 3. Regulatory Data Ingestion & Active Tables

The platform continuously monitors regulatory bodies for updates. 

### The Ingestion Pipeline
1. **Data Sources (Admin Only):** Under the `Admin` menu, Super Admins can configure *Regulatory Data Sources*. These can be APIs, RSS Feeds, or **AI Web Scrapers** via our external Python engine. 
2. When the engine detects a new regulation, it ingests the text, uses AI to extract key metadata (Jurisdiction, Agency, Effective Date), and saves it to the global database.
3. **Auto-Assignment:** If the regulation matches your Organization's jurisdiction and industry, it is automatically added to your library.

### Active Tables
1. Navigate to **Admin > Compliance Tables**.
2. This powerful feature allows you to query your regulation library like a spreadsheet.
3. Click "Create Custom Column" (e.g., "What is the penalty for non-compliance?").
4. The AI will read through the regulations and populate the table cells with exact answers extracted from the legal text.

---

## 4. The Regulatory Change Workflow

When a new regulation is assigned to your Organization, a **Review Workflow** is automatically triggered based on your Organization's custom templates.

### For Compliance Managers: Designing Workflows
1. Go to **Organization Settings > Workflow Templates**.
2. Create sequential steps (e.g., "Initial Legal Review", "CISO Approval", "Board Acknowledgement").
3. Assign each step to specific Roles within your organization. 
4. Define routing logic (e.g., if Legal rejects it, discard the regulation; if approved, send to CISO).

### For Stakeholders: Reviewing Documents
1. Check your **My Reviews** dashboard.
2. Click on a pending review. You will see the AI-summarized regulation alongside the original text.
3. Read the summary, leave comments in the thread, and click the appropriate **Decision Button** (e.g., "Approve", "Require Changes") to advance the workflow to the next department.

---

## 5. Implementation & Task Assignment

Once a regulation has passed review and is deemed applicable, it's time to implement the actual controls.

1. Navigate to a specific **Compliance Control** or **Requirement**.
2. Click **Assign Task**.
3. Select a User, a due date, and describe exactly what needs to be changed (e.g., "Update password policy to require 14 characters").
4. The user will receive an email and see the task on their **My Tasks** Kanban board.
5. As users drag cards to "Completed", management dashboards automatically update to reflect the organization's real-time compliance posture.
