function fullpath = resolvePath(filename)
  file = java.io.File(filename);
  if file.isAbsolute()
      fullpath = string(filename);
  else
      fullpath = string(file.getCanonicalPath());
  end
  fullpath = strrep(fullpath, '\', '/');
  if file.exists()
      return
  else
      error('resolvePath:CannotResolve', 'Does not exist or failed to resolve absolute path for %s.', filename);
  end