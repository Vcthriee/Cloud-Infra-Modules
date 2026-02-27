
# APPLICATION LOAD BALANCER - TRAFFIC DISTRIBUTION
# Layer 7 load balancer (HTTP/HTTPS)

resource "aws_lb" "main" {
  # Unique name (max 32 chars)
  name = "${var.project_name}-alb"
  
  # Internet-facing (public IP)
  internal = false
  
  # Application Load Balancer (not Network LB)
  load_balancer_type = "application"
  
  # Security and network
  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids  # Must be public

  # Settings
  enable_deletion_protection = false  # Set true in production
  enable_http2               = true   # Better performance

  # Access logs to S3
 # access_logs {
  #  bucket  = var.logs_bucket_id
  #  prefix  = "alb-logs"
  #  enabled = true
  #}

  tags = {
    Name = "${var.project_name}-alb"
  }
}
# TARGET GROUP - EC2 INSTANCES FOR ALB
# Health checks and routing

resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2      # 2 consecutive successes = healthy
    interval            = 30     # Check every 30 seconds
    matcher             = "200"  # HTTP 200 OK expected
    path                = "/health"
    port                = "traffic-port"  # Use target group port
    protocol            = "HTTP"
    timeout             = 5      # 5 seconds to respond
    unhealthy_threshold = 3      # 3 failures = unhealthy
  }

  # Seconds to wait for in-flight requests before removing instance
  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# HTTP LISTENER - REDIRECT TO HTTPS
# Port 80 redirects to 443
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"  # Permanent redirect
    }
  }
}

# HTTPS LISTENER - FORWARD TO TARGET GROUP
# Port 443 terminates SSL
#resource "aws_lb_listener" "https" {
 # load_balancer_arn = aws_lb.main.arn
 # port              = "443"
 # protocol          = "HTTPS"
  
  # TLS security policy
 # ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
 # certificate_arn = var.certificate_arn

 # default_action {
 #   type             = "forward"
 #   target_group_arn = aws_lb_target_group.main.arn
 # }
#}