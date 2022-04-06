resource "local_file" "postgres" {
    filename = "./out/postgres/${var.db_name}"
    content = <<EOF
POSTGRES_USERNAME = "postgres@${var.db_name}"
POSTGRES_PASSWORD = "${random_string.admin_passwd.result}"
EOF
}
