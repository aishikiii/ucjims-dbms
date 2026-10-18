// Auth middleware: verifies the JWT issued at login, attaches the user to req.user,
// and gives routes a way to restrict themselves to specific roles (deny-by-default).
const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = payload; // { userId, username, roleName, deptId }
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// Usage: requireRole('Investigator', 'Admin') - allows only those roles through.
// Deny-by-default: any role not explicitly listed is rejected.
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Not authenticated' });
    }
    if (!allowedRoles.includes(req.user.roleName)) {
      return res.status(403).json({
        error: `Role '${req.user.roleName}' is not permitted to perform this action`,
      });
    }
    next();
  };
}

module.exports = { requireAuth, requireRole };
