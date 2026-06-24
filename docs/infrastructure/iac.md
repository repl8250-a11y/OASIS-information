# Infrastructure as Code

## Overview

OASIS infrastructure is managed using Infrastructure as Code (IaC) principles with Terraform, Kubernetes manifests, and Docker configurations.

## Prerequisites

- Terraform 1.0+
- kubectl 1.24+
- Docker 20.10+
- AWS/Azure/GCP CLI configured
- Git for version control

---

## Terraform Configuration

### Project Structure

```
infrastructure/
├── terraform/
│   ├── main.tf              # Main configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── terraform.tfvars     # Variable values
│   ├── backend.tf           # Remote state
│   ├── networking.tf        # VPC, subnets, security groups
│   ├── compute.tf           # EC2, ECS, Kubernetes
│   ├── database.tf          # RDS, ElastiCache
│   ├── monitoring.tf        # CloudWatch, monitoring
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── rds/
│       └── security/
├── kubernetes/
│   ├── namespace.yaml
│   ├── configmaps.yaml
│   ├── secrets.yaml
│   └── deployments/
│       ├── api-gateway.yaml
│       ├── services.yaml
│       └── database.yaml
└── docker/
    ├── Dockerfile
    ├── docker-compose.yml
    └── .dockerignore
```

### Basic Terraform Workflow

```bash
# Initialize Terraform
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy infrastructure
terraform destroy
```

### Example: VPC Configuration

```hcl
# networking.tf

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "oasis-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "oasis-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "oasis-private-${count.index}"
  }
}

resource "aws_security_group" "api" {
  name   = "oasis-api-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "oasis-api-sg"
  }
}
```

### Example: EKS Cluster

```hcl
# compute.tf

resource "aws_eks_cluster" "main" {
  name    = "oasis-cluster"
  version = "1.27"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name = "oasis-cluster"
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "oasis-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  version         = "1.27"

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy
  ]

  tags = {
    Name = "oasis-node-group"
  }
}
```

### Example: RDS Database

```hcl
# database.tf

resource "aws_db_instance" "postgres" {
  identifier       = "oasis-db"
  engine           = "postgres"
  engine_version   = "14.7"
  instance_class   = "db.t3.medium"
  allocated_storage = 100

  db_name  = "oasis"
  username = var.db_username
  password = var.db_password

  multi_az               = true
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "oasis-snapshot-${formatdate("YYYY-MM-DD", timestamp())}"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "oasis-db"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "oasis-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 3
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379

  subnet_group_name      = aws_elasticache_subnet_group.main.name
  security_group_ids     = [aws_security_group.redis.id]
  automatic_failover_enabled = true

  tags = {
    Name = "oasis-redis"
  }
}
```

---

## Kubernetes Manifests

### Namespace

```yaml
# kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: oasis
  labels:
    name: oasis
```

### ConfigMap

```yaml
# kubernetes/configmaps.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: oasis
data:
  LOG_LEVEL: "info"
  API_PORT: "8080"
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  CACHE_HOST: "redis-service"
  CACHE_PORT: "6379"
```

### Secrets

```yaml
# kubernetes/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: oasis
type: Opaque
stringData:
  DB_PASSWORD: "secure-password"
  JWT_SECRET: "jwt-secret-key"
  API_KEY: "api-key"
```

### API Gateway Deployment

```yaml
# kubernetes/deployments/api-gateway.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: oasis
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: oasis:api-gateway-latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /etc/config
      volumes:
      - name: config
        configMap:
          name: app-config
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api-gateway
              topologyKey: kubernetes.io/hostname
```

### Service

```yaml
# kubernetes/services/api-gateway.yaml
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: oasis
spec:
  type: LoadBalancer
  selector:
    app: api-gateway
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
    name: http
  - protocol: TCP
    port: 443
    targetPort: 8080
    name: https
```

### Ingress

```yaml
# kubernetes/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: oasis-ingress
  namespace: oasis
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.oasis.io
    secretName: oasis-tls
  rules:
  - host: api.oasis.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 80
```

---

## Docker Configuration

### Dockerfile

```dockerfile
# docker/Dockerfile

FROM golang:1.20-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server ./cmd/server

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/server .

EXPOSE 8080

CMD ["./server"]
```

### Docker Compose

```yaml
# docker/docker-compose.yml

version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: oasis
      POSTGRES_PASSWORD: password
      POSTGRES_DB: oasis
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

  api:
    build: .
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: oasis
      DB_USER: oasis
      DB_PASSWORD: password
      REDIS_HOST: redis
      REDIS_PORT: 6379
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
  redis_data:
```

---

## State Management

### Remote State (Terraform)

```hcl
# backend.tf

terraform {
  backend "s3" {
    bucket         = "oasis-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

---

## Security

### IAM Roles (Terraform)

```hcl
resource "aws_iam_role" "eks_cluster" {
  name = "oasis-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml

name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Terraform Plan
        run: |
          cd infrastructure/terraform
          terraform init
          terraform plan -out=tfplan
      
      - name: Terraform Apply
        run: |
          cd infrastructure/terraform
          terraform apply tfplan
```

---
*Last Updated: 2026-06-24*
