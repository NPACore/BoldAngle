# 20260505 - track all nifti files used in figures.org
grep -hPo "(?<=[\"'])[^'\" ]*nii.gz" figures.org | sort -u |
  while read f; do
    test -r "$f" || continue
    f=$(readlink -f $f)
    [ -z "$(git ls-files $f)" ] && dryrun git add -f $f || echo "# $f"
done
