workspace "Kairo – C4 Model" "Full architectural description of the Kairo AI‑powered productivity app" {

    ############################################################
    ## 1. MODEL ################################################
    ############################################################
model {
    Person end_user      "End User"          "iOS user who plans tasks and focus sessions with Kairo"
    SoftwareSystem kairo "Kairo"             "AI-powered productivity assistant for iOS"
    SoftwareSystem openai "OpenAI API"       "External LLM provider for NLP and reasoning"
    SoftwareSystem railway "Railway"          "Cloud platform hosting Kairo’s backend containers & PostgreSQL"
    SoftwareSystem healthKit "Apple HealthKit" "Provides HRV & wellness metrics (future integration)"

    end_user -> kairo "Creates tasks, focuses, chats"
        kairo -> openai "Sends prompts / receives completions"
        kairo -> railway "Runs backend & DB on"
        kairo -> healthKit "Reads HRV data (planned)"

        /********************************************************
         *  Level 2 – Container Diagram
         ********************************************************/
        Container iosApp   "iOS App (Host + Client)" "SwiftUI"  "Handles UI, local cache and MCP client logic"
        Container mcpSrv   "MCP Server"              "NestJS  + FastAPI gateway" "REST & MCP endpoints, LLM orchestration"
        Container db       "PostgreSQL"              "RDBMS"   "Tasks, projects, sessions, analytics"
        Container vectordb "Embeddings Store"        "pgvector extension" "Semantic search (planned)"

        kairo -> iosApp
        iosApp -> mcpSrv  "JSON/HTTPS (MCP Protocol)"
        mcpSrv -> db      "SQL"
        mcpSrv -> vectordb "Similarity queries" 
        mcpSrv -> openai  "Prompt/Completion (HTTPS)"

        /********************************************************
         *  Level 3 – Component Diagram (selected containers)
         ********************************************************/
        Component apiLayer         "API Layer"       "NestJS Controllers"     "Validates requests, auth, rate‑limit"
        Component taskService      "Task Service"    "NestJS Provider"        "Business logic & CRUD for tasks/projects"
        Component focusService     "Focus Service"   "NestJS Provider"        "Start/stop focus sessions, metrics"
        Component aiGateway        "AI Gateway"      "FastAPI"                "Formats prompts, calls LLMs, post‑processes"
        Component repository       "Repository"      "TypeORM"                "Maps domain ↔ relational tables"

        mcpSrv -> apiLayer
        apiLayer -> taskService
        apiLayer -> focusService
        apiLayer -> aiGateway        "Delegates NLP"
        taskService  -> repository
        focusService -> repository
        repository   -> db
        aiGateway    -> openai

        Component hostLayer   "Host Layer"   "SwiftUI App Delegate" "App lifecycle, dependency injection"
        Component clientLayer "MCP Client"   "Swift Package"        "Encapsulates requests, background sync"
        Component uiViews     "UI Views"     "SwiftUI Components"   "Dashboard, Task List, Chat, Focus"

        iosApp -> hostLayer
        hostLayer -> clientLayer
        clientLayer -> uiViews            "Publishes state"
        clientLayer -> mcpSrv             "REST/MCP"
        uiViews -> end_user

        /********************************************************
         *  Level 4 – Deployment (runtime)
         ********************************************************/
        DeploymentEnvironment "Production" {
            node device "iOS Device" {
                iosApp
            }

            node railwayCloud "Railway Project" {
                node dockerHost "Docker Container (NestJS)" {
                    mcpSrv
                }
                node postgresNode "Managed PostgreSQL (Railway)" {
                    db
                    vectordb
                }
            }

            node openaiCloud "OpenAI Cloud" {
                openai
            }

            iosApp -> mcpSrv
            mcpSrv -> db
            mcpSrv -> openai
        }
    }

    ############################################################
    ## 2. VIEWS ###############################################
    ############################################################
    views {
        systemContext kairo "SystemContext" {
            include *
            autolayout lr
            title "Kairo – System Context"
        }

        container kairo "Container" {
            include end_user
            include iosApp
            include mcpSrv
            include db
            include vectordb
            include openai
            autolayout lr
            title "Kairo – Container Diagram"
        }

        component mcpSrv "Backend Components" {
            include apiLayer
            include taskService
            include focusService
            include aiGateway
            include repository
            include db
            include openai
            autolayout lr
            title "MCP Server – Component Diagram"
        }

        component iosApp "iOS Components" {
            include hostLayer
            include clientLayer
            include uiViews
            include end_user
            autolayout lr
            title "iOS App – Component Diagram"
        }

        deployment "Production" {
            include *
            autolayout lr
            title "Production Deployment"
        }

        theme default
    }

    ############################################################
    ## 3. STYLES ##############################################
    ############################################################
    styles {
        element "Person"             { shape person   background #08427b  color #ffffff }
        element "Software System"    { background #1168bd  color #ffffff }
        element "Container"          { background #438dd5  color #ffffff }
        element "Component"          { background #85bbf0  color #000000 }
        element "Database"           { shape cylinders }
    }
}