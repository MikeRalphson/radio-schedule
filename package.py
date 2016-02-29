def package(mbt):

    source_file = mbt.name + '.tar.gz'

    # source prepare
    # FIXME: the exclude list is a bit yucky
    mbt.run([
      'tar', '-czf', mbt.sources_dir + '/' + source_file,
      '--exclude-vcs',
      '--exclude=.DS_Store',
      'app', 'config.ru', 'Gemfile', 'Gemfile.lock', 'scripts'
    ], cwd=mbt.root + '/')

    mbt.spec.add_source(source_file)
    mbt.spec.set_build_arch(None)
    mbt.spec.set_prep('%setup -c -n ' + mbt.name)

    mbt.spec.add_build_steps([
        ['scl', 'enable', 'ruby193', '"bundle install --deployment"'],
    ])

    app_dir = "%{buildroot}/usr/lib/" + mbt.name + "/"
    mbt.spec.add_install_steps([
        ["rm", "-rf", "%{buildroot}"],
        ["mkdir", "-p", app_dir],
        ["mkdir", "-p", "%{buildroot}%{_initddir}"],
        ["mv", "scripts/start.sh", app_dir],
        ["mv", "scripts/initd.sh", "%{buildroot}%{_initddir}/" + mbt.name],
        ["cp", "-rf", ".", app_dir]
    ])

    mbt.spec.add_post_steps([
        ["/sbin/chkconfig", "--add", mbt.name],
    ])

    mbt.spec.add_preun_steps([
        ["/sbin/chkconfig", "--del", mbt.name],
    ])


    # %files
    mbt.spec.add_files(["%{_initddir}"], file_permissions=755)
    mbt.spec.add_files(["/usr/lib/" + mbt.name], file_permissions=644, dir_permissions=755)
    mbt.spec.add_files(["/usr/lib/" + mbt.name + '/start.sh'], file_permissions=755)
    mbt.spec.add_files(["/usr/lib/" + mbt.name + '/vendor/bundle/ruby/1.9.1/bin'], file_permissions=755)
