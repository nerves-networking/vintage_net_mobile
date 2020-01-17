#include <ctype.h>
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <ei.h>

extern char **environ;

#define SOCKET_PATH "/tmp/vintage_net/pppd_comms"

static int starts_with(const char *str, const char *prefix)
{
    size_t len = strlen(prefix);
    return strncmp(str, prefix, len) == 0;
}

static const char *ppp_vars[] = {
    "DEVICE",
    "IFNAME",
    "IPLOCAL",
    "IPREMOTE",
    "PEERNAME",
    "SPEED",
    "ORIG_UID",
    "PPPLOGNAME",
    "CONNECT_TIME",
    "BYTES_SENT",
    "BYTES_RCVD",
    "LINKNAME",
    "CALL_FILE",
    "DNS1",
    "DNS2",
    "PPPD_PID",
    "USEPEERDNS",
    NULL
};

static int should_encode(const char *kv)
{
    for (int i = 0; ppp_vars[i]; i++) {
        if (starts_with(kv, ppp_vars[i]))
            return 1;
    }
    return 0;
}

static int encode_string(ei_x_buff *buff, const char *str)
{
    // Encode strings as binaries so that we get Elixir strings
    // NOTE: the strings that we encounter here are expected to be ASCII to
    //       my knowledge
    return ei_x_encode_binary(buff, str, strlen(str));
}

static int encode_kv_string(ei_x_buff *buff, const char *key, const char *str)
{
    if (ei_x_encode_atom(buff, key) == 0 && encode_string(buff, str) == 0)
        return 0;
    else
        return -1;
}

static int count_items(char *const* p)
{
    int n = 0;
    while (*p != NULL) {
        if (should_encode(*p))
            n++;
        p++;
    }

    return n;
}

static int encode_env_kv(ei_x_buff *buff, const char *kv)
{
    char key[32];

    const char *equal = strchr(kv, '=');
    if (equal == NULL)
        return -1;

    size_t keylen = equal - kv;
    if (keylen >= sizeof(key))
        keylen = sizeof(key) - 1;
    memcpy(key, kv, keylen);
    key[keylen] = '\0';

    const char *value = equal + 1;

    return encode_kv_string(buff, key, value);
}

static int encode_environ(ei_x_buff *buff)
{
    int kv_to_encode = count_items(environ);
    if (ei_x_encode_map_header(buff, kv_to_encode) < 0)
        return -1;

    for (char **p = environ;
        *p != NULL;
        p++) {
        if (should_encode(*p)) {
            if (encode_env_kv(buff, *p) < 0)
                return -1;
        }
    }

    return 0;
}

static int encode_args(ei_x_buff *buff, int argc, char *argv[])
{
    if (ei_x_encode_list_header(buff, argc) < 0)
        return -1;

    int i;
    for (i = 0; i < argc; i++) {
       if (encode_string(buff, argv[i]) < 0)
           return -1;
    }

    return ei_x_encode_empty_list(buff);
}

int main(int argc, char *argv[])
{
    int fd = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (fd < 0)
        err(EXIT_FAILURE, "socket");

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) == -1)
        err(EXIT_FAILURE, "connect");

    ei_x_buff buff;
    if (ei_x_new_with_version(&buff) == 0 &&
        ei_x_encode_tuple_header(&buff, 2) == 0 &&
        encode_args(&buff, argc, argv) == 0 &&
        encode_environ(&buff) == 0) {

        ssize_t rc = write(fd, buff.buff, buff.index);
        if (rc < 0)
            err(EXIT_FAILURE, "write");

        if (rc != buff.index)
             errx(EXIT_FAILURE, "write wasn't able to send %d chars all at once!", buff.index);
    } else {
        errx(EXIT_FAILURE, "encoding failed");
    }

    close(fd);
    return 0;
}

