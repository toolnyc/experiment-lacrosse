-- Update admin domain check to support both old and new brand domains
-- This allows both @thelacrosselab.com and @experimentlacrosse.com to be recognized as admin emails

-- Update the is_admin_user() function to check for both domains
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND (
      auth.users.email ~~ '%@thelacrosselab.com'::text
      OR auth.users.email ~~ '%@experimentlacrosse.com'::text
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- No need to recreate policies - they reference the function which is now updated
