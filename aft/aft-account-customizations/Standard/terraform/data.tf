data "aws_ssm_parameter" "exec_role_name" {
  name = "/aft/output/exec-role-name"
}
