import 'package:flutter/material.dart';

// ==================== COLORS ====================

class AppColors {
  // Primary & Accent
  static const Color primary = Color(0xFF7C4DFF);
  static const Color secondary = Color(0xFFA855F7);
  static const Color accent = Color(0xFF00E5A8);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color expense = Color(0xFFFF4D6D);
  static const Color income = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4D6D);

  // Background & Surface
  static const Color background = Color(0xFF09090F);
  static const Color surface = Color(0xFF14141D);
  static const Color card = Color(0xFF1C1C28);
  static const Color cardLight = Color(0xFF28283A);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3B2);
  static const Color textTertiary = Color(0xFF6B6B7F);

  // Borders
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color borderLight = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)

  // Gradient Colors (for glowing purple effects)
  static const Color gradientStart = Color(0xFF7C4DFF);
  static const Color gradientMid = Color(0xFFA855F7);
  static const Color gradientEnd = Color(0xFFD946EF);

  // Glassmorphism overlay colors
  static const Color glassOverlay = Color(0x1AFFFFFF); // rgba(255,255,255,0.10)
  static const Color glassBorder = Color(0x33FFFFFF);

  static List<BoxShadow>? get cardShadow => null;

  static Color? get textLight => null;

  static Gradient? get primaryGradient => null;

  static Color? get textDark => null; // rgba(255,255,255,0.20)
}

// ==================== GRADIENTS ====================

class AppGradients {
  // Primary glowing purple gradient
  static const LinearGradient primary = LinearGradient(
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMid,
      AppColors.gradientEnd,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary gradient for buttons and highlights
  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.secondary, AppColors.gradientStart],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Accent gradient (green)
  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accent, Color(0xFF00E5A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background gradient (subtle dark)
  static const LinearGradient background = LinearGradient(
    colors: [AppColors.background, AppColors.surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Card gradient (glass effect)
  static const LinearGradient card = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glowing gradient for circular progress/glows
  static const RadialGradient glow = RadialGradient(
    colors: [Color(0x337C4DFF), Colors.transparent],
    radius: 1.0,
  );
}

// ==================== SHADOWS ====================

class AppShadows {
  // Soft shadow for cards and containers
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x1A7C4DFF), // primary with 10% opacity
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];

  // Medium shadow for elevated elements
  static List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x2A7C4DFF), // primary with 16% opacity
      blurRadius: 40,
      offset: Offset(0, 15),
    ),
  ];

  // Glowing shadow for accent elements
  static List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x4D00E5A8), // accent with 30% opacity
      blurRadius: 30,
      offset: Offset(0, 0),
    ),
  ];

  // Glassmorphism shadow
  static List<BoxShadow> glass = [
    BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

// ==================== TEXT STYLES ====================

class AppTextStyles {
  static const String fontFamily = 'Inter'; // or 'SF Pro Display' if available

  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.4,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  // Special
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle amountLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.2,
  );

  static get subHeading => null;
}

// ==================== DECORATIONS ====================

class AppDecorations {
  // Glassmorphism card decoration
  static BoxDecoration glassCard({double borderRadius = 24, double blur = 20}) {
    return BoxDecoration(
      gradient: AppGradients.card,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: AppShadows.glass,
    );
  }

  // Premium card with gradient background
  static BoxDecoration gradientCard({
    double borderRadius = 24,
    required LinearGradient gradient,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: AppShadows.soft,
    );
  }

  // Glowing circle for decorative elements
  static BoxDecoration glowingCircle({
    double size = 100,
    Color color = AppColors.primary,
    double opacity = 0.15,
  }) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(opacity),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 40,
          spreadRadius: 10,
        ),
      ],
    );
  }
}

// ==================== SPACING ====================

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  // 8pt grid system
  static const double grid = 8;
  static const double grid2 = 16;
  static const double grid3 = 24;
  static const double grid4 = 32;
  static const double grid5 = 40;
  static const double grid6 = 48;
}

// ==================== BORDER RADIUS ====================

class AppRadius {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
  static const double xlarge = 30;
  static const double circular = 9999;
}
