function requireRole(role) {
  return (req, res, next) => {
    if (!req.user || !req.user.uid)
      return res.status(401).json({ error: "Unauthorized" });
    const claims = req.user;
    if (claims.role !== role) {
      return res.status(403).json({ error: "Forbidden: insufficient role" });
    }
    return next();
  };
}

module.exports = requireRole;
