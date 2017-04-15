resource "aws_instance" "origin" {
    ami = "${data.aws_ami.ubuntu.id}"
    #region = "${var.azone}"
    instance_type = "t2.small"
    associate_public_ip_address = "true"
    security_groups = ["allow_ssh", "allow_http"]
    key_name = "${aws_key_pair.wp-key.key_name}"
    tags {
        Name = "origin"
    }
}