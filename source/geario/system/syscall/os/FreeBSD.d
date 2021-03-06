/*
 * Geario - A cross-platform abstraction library with asynchronous I/O.
 *
 * Copyright (C) 2021-2022 Kerisy.com
 *
 * Website: https://www.kerisy.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module geario.system.syscall.os.FreeBSD;
/*
 * System call numbers.
 *
 * DO NOT EDIT-- this file is automatically generated.
 * $FreeBSD: releng/11.2/sys/sys/syscall.h 318164 2017-05-10 23:09:17Z jhb $
 */

version(FreeBSD):

enum SYS_syscall = 0;
enum SYS_exit = 1;
enum SYS_fork = 2;
enum SYS_read = 3;
enum SYS_write = 4;
enum SYS_open = 5;
enum SYS_close = 6;
enum SYS_wait4 = 7;
                /* 8 is old creat */
enum SYS_link = 9;
enum SYS_unlink = 10;
                /* 11 is obsolete execv */
enum SYS_chdir = 12;
enum SYS_fchdir = 13;
enum SYS_mknod = 14;
enum SYS_chmod = 15;
enum SYS_chown = 16;
enum SYS_break = 17;
                /* 18 is freebsd4 getfsstat */
                /* 19 is old lseek */
enum SYS_getpid = 20;
enum SYS_mount = 21;
enum SYS_unmount = 22;
enum SYS_setuid = 23;
enum SYS_getuid = 24;
enum SYS_geteuid = 25;
enum SYS_ptrace = 26;
enum SYS_recvmsg = 27;
enum SYS_sendmsg = 28;
enum SYS_recvfrom = 29;
enum SYS_accept = 30;
enum SYS_getpeername = 31;
enum SYS_getsockname = 32;
enum SYS_access = 33;
enum SYS_chflags = 34;
enum SYS_fchflags = 35;
enum SYS_sync = 36;
enum SYS_kill = 37;
                /* 38 is old stat */
enum SYS_getppid = 39;
                /* 40 is old lstat */
enum SYS_dup = 41;
enum SYS_freebsd10_pipe = 42;
enum SYS_getegid = 43;
enum SYS_profil = 44;
enum SYS_ktrace = 45;
                /* 46 is old sigaction */
enum SYS_getgid = 47;
                /* 48 is old sigprocmask */
enum SYS_getlogin = 49;
enum SYS_setlogin = 50;
enum SYS_acct = 51;
                /* 52 is old sigpending */
enum SYS_sigaltstack = 53;
enum SYS_ioctl = 54;
enum SYS_reboot = 55;
enum SYS_revoke = 56;
enum SYS_symlink = 57;
enum SYS_readlink = 58;
enum SYS_execve = 59;
enum SYS_umask = 60;
enum SYS_chroot = 61;
                /* 62 is old fstat */
                /* 63 is old getkerninfo */
                /* 64 is old getpagesize */
enum SYS_msync = 65;
enum SYS_vfork = 66;
                /* 67 is obsolete vread */
                /* 68 is obsolete vwrite */
enum SYS_sbrk = 69;
enum SYS_sstk = 70;
                /* 71 is old mmap */
enum SYS_vadvise = 72;
enum SYS_munmap = 73;
enum SYS_mprotect = 74;
enum SYS_madvise = 75;
                /* 76 is obsolete vhangup */
                /* 77 is obsolete vlimit */
enum SYS_mincore = 78;
enum SYS_getgroups = 79;
enum SYS_setgroups = 80;
enum SYS_getpgrp = 81;
enum SYS_setpgid = 82;
enum SYS_setitimer = 83;
                /* 84 is old wait */
enum SYS_swapon = 85;
enum SYS_getitimer = 86;
                /* 87 is old gethostname */
                /* 88 is old sethostname */
enum SYS_getdtablesize = 89;
enum SYS_dup2 = 90;
enum SYS_fcntl = 92;
enum SYS_select = 93;
enum SYS_fsync = 95;
enum SYS_setpriority = 96;
enum SYS_socket = 97;
enum SYS_connect = 98;
                /* 99 is old accept */
enum SYS_getpriority = 100;
                /* 101 is old send */
                /* 102 is old recv */
                /* 103 is old sigreturn */
enum SYS_bind = 104;
enum SYS_setsockopt = 105;
enum SYS_listen = 106;
                /* 107 is obsolete vtimes */
                /* 108 is old sigvec */
                /* 109 is old sigblock */
                /* 110 is old sigsetmask */
                /* 111 is old sigsuspend */
                /* 112 is old sigstack */
                /* 113 is old recvmsg */
                /* 114 is old sendmsg */
                /* 115 is obsolete vtrace */
enum SYS_gettimeofday = 116;
enum SYS_getrusage = 117;
enum SYS_getsockopt = 118;
enum SYS_readv = 120;
enum SYS_writev = 121;
enum SYS_settimeofday = 122;
enum SYS_fchown = 123;
enum SYS_fchmod = 124;
                /* 125 is old recvfrom */
enum SYS_setreuid = 126;
enum SYS_setregid = 127;
enum SYS_rename = 128;
                /* 129 is old truncate */
                /* 130 is old ftruncate */
enum SYS_flock = 131;
enum SYS_mkfifo = 132;
enum SYS_sendto = 133;
enum SYS_shutdown = 134;
enum SYS_socketpair = 135;
enum SYS_mkdir = 136;
enum SYS_rmdir = 137;
enum SYS_utimes = 138;
                /* 139 is obsolete 4.2 sigreturn */
enum SYS_adjtime = 140;
                /* 141 is old getpeername */
                /* 142 is old gethostid */
                /* 143 is old sethostid */
                /* 144 is old getrlimit */
                /* 145 is old setrlimit */
                /* 146 is old killpg */
enum SYS_setsid = 147;
enum SYS_quotactl = 148;
                /* 149 is old quota */
                /* 150 is old getsockname */
enum SYS_nlm_syscall = 154;
enum SYS_nfssvc = 155;
                /* 156 is old getdirentries */
                /* 157 is freebsd4 statfs */
                /* 158 is freebsd4 fstatfs */
enum SYS_lgetfh = 160;
enum SYS_getfh = 161;
                /* 162 is freebsd4 getdomainname */
                /* 163 is freebsd4 setdomainname */
                /* 164 is freebsd4 uname */
enum SYS_sysarch = 165;
enum SYS_rtprio = 166;
enum SYS_semsys = 169;
enum SYS_msgsys = 170;
enum SYS_shmsys = 171;
                /* 173 is freebsd6 pread */
                /* 174 is freebsd6 pwrite */
enum SYS_setfib = 175;
enum SYS_ntp_adjtime = 176;
enum SYS_setgid = 181;
enum SYS_setegid = 182;
enum SYS_seteuid = 183;
enum SYS_stat = 188;
enum SYS_fstat = 189;
enum SYS_lstat = 190;
enum SYS_pathconf = 191;
enum SYS_fpathconf = 192;
enum SYS_getrlimit = 194;
enum SYS_setrlimit = 195;
enum SYS_getdirentries = 196;
                /* 197 is freebsd6 mmap */
enum SYS___syscall = 198;
                /* 199 is freebsd6 lseek */
                /* 200 is freebsd6 truncate */
                /* 201 is freebsd6 ftruncate */
enum SYS___sysctl = 202;
enum SYS_mlock = 203;
enum SYS_munlock = 204;
enum SYS_undelete = 205;
enum SYS_futimes = 206;
enum SYS_getpgid = 207;
enum SYS_poll = 209;
enum SYS_freebsd7___semctl = 220;
enum SYS_semget = 221;
enum SYS_semop = 222;
enum SYS_freebsd7_msgctl = 224;
enum SYS_msgget = 225;
enum SYS_msgsnd = 226;
enum SYS_msgrcv = 227;
enum SYS_shmat = 228;
enum SYS_freebsd7_shmctl = 229;
enum SYS_shmdt = 230;
enum SYS_shmget = 231;
enum SYS_clock_gettime = 232;
enum SYS_clock_settime = 233;
enum SYS_clock_getres = 234;
enum SYS_ktimer_create = 235;
enum SYS_ktimer_delete = 236;
enum SYS_ktimer_settime = 237;
enum SYS_ktimer_gettime = 238;
enum SYS_ktimer_getoverrun = 239;
enum SYS_nanosleep = 240;
enum SYS_ffclock_getcounter = 241;
enum SYS_ffclock_setestimate = 242;
enum SYS_ffclock_getestimate = 243;
enum SYS_clock_nanosleep = 244;
enum SYS_clock_getcpuclockid2 = 247;
enum SYS_ntp_gettime = 248;
enum SYS_minherit = 250;
enum SYS_rfork = 251;
enum SYS_openbsd_poll = 252;
enum SYS_issetugid = 253;
enum SYS_lchown = 254;
enum SYS_aio_read = 255;
enum SYS_aio_write = 256;
enum SYS_lio_listio = 257;
enum SYS_getdents = 272;
enum SYS_lchmod = 274;
enum SYS_netbsd_lchown = 275;
enum SYS_lutimes = 276;
enum SYS_netbsd_msync = 277;
enum SYS_nstat = 278;
enum SYS_nfstat = 279;
enum SYS_nlstat = 280;
enum SYS_preadv = 289;
enum SYS_pwritev = 290;
                /* 297 is freebsd4 fhstatfs */
enum SYS_fhopen = 298;
enum SYS_fhstat = 299;
enum SYS_modnext = 300;
enum SYS_modstat = 301;
enum SYS_modfnext = 302;
enum SYS_modfind = 303;
enum SYS_kldload = 304;
enum SYS_kldunload = 305;
enum SYS_kldfind = 306;
enum SYS_kldnext = 307;
enum SYS_kldstat = 308;
enum SYS_kldfirstmod = 309;
enum SYS_getsid = 310;
enum SYS_setresuid = 311;
enum SYS_setresgid = 312;
                /* 313 is obsolete signanosleep */
enum SYS_aio_return = 314;
enum SYS_aio_suspend = 315;
enum SYS_aio_cancel = 316;
enum SYS_aio_error = 317;
                /* 318 is freebsd6 aio_read */
                /* 319 is freebsd6 aio_write */
                /* 320 is freebsd6 lio_listio */
enum SYS_yield = 321;
                /* 322 is obsolete thr_sleep */
                /* 323 is obsolete thr_wakeup */
enum SYS_mlockall = 324;
enum SYS_munlockall = 325;
enum SYS___getcwd = 326;
enum SYS_sched_setparam = 327;
enum SYS_sched_getparam = 328;
enum SYS_sched_setscheduler = 329;
enum SYS_sched_getscheduler = 330;
enum SYS_sched_yield = 331;
enum SYS_sched_get_priority_max = 332;
enum SYS_sched_get_priority_min = 333;
enum SYS_sched_rr_get_interval = 334;
enum SYS_utrace = 335;
                /* 336 is freebsd4 sendfile */
enum SYS_kldsym = 337;
enum SYS_jail = 338;
enum SYS_nnpfs_syscall = 339;
enum SYS_sigprocmask = 340;
enum SYS_sigsuspend = 341;
                /* 342 is freebsd4 sigaction */
enum SYS_sigpending = 343;
                /* 344 is freebsd4 sigreturn */
enum SYS_sigtimedwait = 345;
enum SYS_sigwaitinfo = 346;
enum SYS___acl_get_file = 347;
enum SYS___acl_set_file = 348;
enum SYS___acl_get_fd = 349;
enum SYS___acl_set_fd = 350;
enum SYS___acl_delete_file = 351;
enum SYS___acl_delete_fd = 352;
enum SYS___acl_aclcheck_file = 353;
enum SYS___acl_aclcheck_fd = 354;
enum SYS_extattrctl = 355;
enum SYS_extattr_set_file = 356;
enum SYS_extattr_get_file = 357;
enum SYS_extattr_delete_file = 358;
enum SYS_aio_waitcomplete = 359;
enum SYS_getresuid = 360;
enum SYS_getresgid = 361;
enum SYS_kqueue = 362;
enum SYS_kevent = 363;
enum SYS_extattr_set_fd = 371;
enum SYS_extattr_get_fd = 372;
enum SYS_extattr_delete_fd = 373;
enum SYS___setugid = 374;
enum SYS_eaccess = 376;
enum SYS_afs3_syscall = 377;
enum SYS_nmount = 378;
enum SYS___mac_get_proc = 384;
enum SYS___mac_set_proc = 385;
enum SYS___mac_get_fd = 386;
enum SYS___mac_get_file = 387;
enum SYS___mac_set_fd = 388;
enum SYS___mac_set_file = 389;
enum SYS_kenv = 390;
enum SYS_lchflags = 391;
enum SYS_uuidgen = 392;
enum SYS_sendfile = 393;
enum SYS_mac_syscall = 394;
enum SYS_getfsstat = 395;
enum SYS_statfs = 396;
enum SYS_fstatfs = 397;
enum SYS_fhstatfs = 398;
enum SYS_ksem_close = 400;
enum SYS_ksem_post = 401;
enum SYS_ksem_wait = 402;
enum SYS_ksem_trywait = 403;
enum SYS_ksem_init = 404;
enum SYS_ksem_open = 405;
enum SYS_ksem_unlink = 406;
enum SYS_ksem_getvalue = 407;
enum SYS_ksem_destroy = 408;
enum SYS___mac_get_pid = 409;
enum SYS___mac_get_link = 410;
enum SYS___mac_set_link = 411;
enum SYS_extattr_set_link = 412;
enum SYS_extattr_get_link = 413;
enum SYS_extattr_delete_link = 414;
enum SYS___mac_execve = 415;
enum SYS_sigaction = 416;
enum SYS_sigreturn = 417;
enum SYS_getcontext = 421;
enum SYS_setcontext = 422;
enum SYS_swapcontext = 423;
enum SYS_swapoff = 424;
enum SYS___acl_get_link = 425;
enum SYS___acl_set_link = 426;
enum SYS___acl_delete_link = 427;
enum SYS___acl_aclcheck_link = 428;
enum SYS_sigwait = 429;
enum SYS_thr_create = 430;
enum SYS_thr_exit = 431;
enum SYS_thr_self = 432;
enum SYS_thr_kill = 433;
enum SYS_jail_attach = 436;
enum SYS_extattr_list_fd = 437;
enum SYS_extattr_list_file = 438;
enum SYS_extattr_list_link = 439;
enum SYS_ksem_timedwait = 441;
enum SYS_thr_suspend = 442;
enum SYS_thr_wake = 443;
enum SYS_kldunloadf = 444;
enum SYS_audit = 445;
enum SYS_auditon = 446;
enum SYS_getauid = 447;
enum SYS_setauid = 448;
enum SYS_getaudit = 449;
enum SYS_setaudit = 450;
enum SYS_getaudit_addr = 451;
enum SYS_setaudit_addr = 452;
enum SYS_auditctl = 453;
enum SYS__umtx_op = 454;
enum SYS_thr_new = 455;
enum SYS_sigqueue = 456;
enum SYS_kmq_open = 457;
enum SYS_kmq_setattr = 458;
enum SYS_kmq_timedreceive = 459;
enum SYS_kmq_timedsend = 460;
enum SYS_kmq_notify = 461;
enum SYS_kmq_unlink = 462;
enum SYS_abort2 = 463;
enum SYS_thr_set_name = 464;
enum SYS_aio_fsync = 465;
enum SYS_rtprio_thread = 466;
enum SYS_sctp_peeloff = 471;
enum SYS_sctp_generic_sendmsg = 472;
enum SYS_sctp_generic_sendmsg_iov = 473;
enum SYS_sctp_generic_recvmsg = 474;
enum SYS_pread = 475;
enum SYS_pwrite = 476;
enum SYS_mmap = 477;
enum SYS_lseek = 478;
enum SYS_truncate = 479;
enum SYS_ftruncate = 480;
enum SYS_thr_kill2 = 481;
enum SYS_shm_open = 482;
enum SYS_shm_unlink = 483;
enum SYS_cpuset = 484;
enum SYS_cpuset_setid = 485;
enum SYS_cpuset_getid = 486;
enum SYS_cpuset_getaffinity = 487;
enum SYS_cpuset_setaffinity = 488;
enum SYS_faccessat = 489;
enum SYS_fchmodat = 490;
enum SYS_fchownat = 491;
enum SYS_fexecve = 492;
enum SYS_fstatat = 493;
enum SYS_futimesat = 494;
enum SYS_linkat = 495;
enum SYS_mkdirat = 496;
enum SYS_mkfifoat = 497;
enum SYS_mknodat = 498;
enum SYS_openat = 499;
enum SYS_readlinkat = 500;
enum SYS_renameat = 501;
enum SYS_symlinkat = 502;
enum SYS_unlinkat = 503;
enum SYS_posix_openpt = 504;
enum SYS_gssd_syscall = 505;
enum SYS_jail_get = 506;
enum SYS_jail_set = 507;
enum SYS_jail_remove = 508;
enum SYS_closefrom = 509;
enum SYS___semctl = 510;
enum SYS_msgctl = 511;
enum SYS_shmctl = 512;
enum SYS_lpathconf = 513;
                /* 514 is obsolete cap_new */
enum SYS___cap_rights_get = 515;
enum SYS_cap_enter = 516;
enum SYS_cap_getmode = 517;
enum SYS_pdfork = 518;
enum SYS_pdkill = 519;
enum SYS_pdgetpid = 520;
enum SYS_pselect = 522;
enum SYS_getloginclass = 523;
enum SYS_setloginclass = 524;
enum SYS_rctl_get_racct = 525;
enum SYS_rctl_get_rules = 526;
enum SYS_rctl_get_limits = 527;
enum SYS_rctl_add_rule = 528;
enum SYS_rctl_remove_rule = 529;
enum SYS_posix_fallocate = 530;
enum SYS_posix_fadvise = 531;
enum SYS_wait6 = 532;
enum SYS_cap_rights_limit = 533;
enum SYS_cap_ioctls_limit = 534;
enum SYS_cap_ioctls_get = 535;
enum SYS_cap_fcntls_limit = 536;
enum SYS_cap_fcntls_get = 537;
enum SYS_bindat = 538;
enum SYS_connectat = 539;
enum SYS_chflagsat = 540;
enum SYS_accept4 = 541;
enum SYS_pipe2 = 542;
enum SYS_aio_mlock = 543;
enum SYS_procctl = 544;
enum SYS_ppoll = 545;
enum SYS_futimens = 546;
enum SYS_utimensat = 547;
enum SYS_numa_getaffinity = 548;
enum SYS_numa_setaffinity = 549;
enum SYS_fdatasync = 550;
enum SYS_MAXSYSCALL = 551;
