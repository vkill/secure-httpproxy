function access(s) {
    if (s.variables.proxy_pass == "") {
        s.deny();
        return;
    }
    s.allow();
}
