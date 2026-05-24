import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';

class AppL10n {
  final String locale;
  const AppL10n(this.locale);

  bool get isFr => locale == 'fr';
  bool get _fr => isFr;

  // ── App ──────────────────────────────────────────────────────────────────────
  String get appName => 'QuickTZ';
  String get tagline =>
      _fr ? 'Voyagez Mieux, Réservez Plus Vite' : 'Travel Smarter, Book Faster';

  // ── Navigation ───────────────────────────────────────────────────────────────
  String get home => _fr ? 'Accueil' : 'Home';
  String get search => _fr ? 'Rechercher' : 'Search';
  String get tickets => _fr ? 'Billets' : 'Tickets';
  String get notifications => _fr ? 'Notifications' : 'Notifications';
  String get profile => _fr ? 'Profil' : 'Profile';

  // ── Drawer ───────────────────────────────────────────────────────────────────
  String get myProfile => _fr ? 'Mon Profil' : 'My Profile';
  String get askBot => _fr ? 'Demander au Bot QuickTZ' : 'Ask QuickTZ Bot';
  String get tripPlanner => _fr ? 'Planificateur de Voyage' : 'Trip Planner';
  String get myTickets => _fr ? 'Mes Billets' : 'My Tickets';
  String get giftCards => _fr ? 'Cartes Cadeaux' : 'Gift Cards';
  String get helpSupport => _fr ? 'Aide & Support' : 'Help & Support';
  String get settings => _fr ? 'Paramètres' : 'Settings';
  String get logOut => _fr ? 'Se Déconnecter' : 'Log Out';
  String get guest => _fr ? 'Invité' : 'Guest';
  String get premiumMember => _fr ? 'Membre Premium' : 'Premium Member';
  String get freePlan => _fr ? 'Plan Gratuit' : 'Free Plan';
  String get comingSoon =>
      _fr ? 'Bientôt disponible' : 'Coming soon';

  // ── Auth ─────────────────────────────────────────────────────────────────────
  String get login => _fr ? 'Connexion' : 'Login';
  String get createAccount => _fr ? 'Créer un Compte' : 'Create Account';
  String get email => _fr ? 'Email' : 'Email';
  String get phoneNumber => _fr ? 'Numéro de Téléphone' : 'Phone Number';
  String get password => _fr ? 'Mot de Passe' : 'Password';
  String get fullName => _fr ? 'Nom Complet' : 'Full Name';
  String get forgotPassword =>
      _fr ? 'Mot de Passe Oublié ?' : 'Forgot Password?';
  String get dontHaveAccount =>
      _fr ? "Pas encore de compte ? " : "Don't have an account? ";
  String get alreadyHaveAccount =>
      _fr ? 'Déjà un compte ? ' : 'Already have an account? ';
  String get signUp => _fr ? "S'inscrire" : 'Sign Up';
  String get signIn => _fr ? 'Se Connecter' : 'Sign In';
  String get loginWithEmail =>
      _fr ? 'Connexion par Email' : 'Login with Email';
  String get loginWithPhone =>
      _fr ? 'Connexion par Téléphone' : 'Login with Phone';
  String get welcomeBack => _fr ? 'Bon Retour !' : 'Welcome Back!';
  String get enterCredentials =>
      _fr ? 'Entrez vos identifiants pour continuer' : 'Enter your credentials to continue';
  String get continueStr => _fr ? 'Continuer' : 'Continue';

  // ── Home ─────────────────────────────────────────────────────────────────────
  String get whereAreYouGoing =>
      _fr ? 'Où allez-vous ?' : 'Where are you going?';
  String get popularRoutes => _fr ? 'Itinéraires Populaires' : 'Popular Routes';
  String get featuredAgencies =>
      _fr ? 'Agences en Vedette' : 'Featured Agencies';
  String get upcomingTrips => _fr ? 'Prochains Voyages' : 'Upcoming Trips';
  String get searchTrips => _fr ? 'Rechercher des Voyages' : 'Search Trips';
  String get goodMorning => _fr ? 'Bonjour' : 'Good morning';
  String get goodAfternoon => _fr ? 'Bon après-midi' : 'Good afternoon';
  String get goodEvening => _fr ? 'Bonsoir' : 'Good evening';
  String get bookYourNextTrip =>
      _fr ? 'Réservez votre prochain voyage' : 'Book your next trip';
  String get viewAll => _fr ? 'Voir tout' : 'View all';
  String get noTripsScheduled =>
      _fr ? 'Aucun voyage à venir' : 'No upcoming trips';
  String get searchNow => _fr ? 'Rechercher maintenant' : 'Search now';

  // ── Search ───────────────────────────────────────────────────────────────────
  String get from => _fr ? 'De' : 'From';
  String get to => _fr ? 'À' : 'To';
  String get date => _fr ? 'Date' : 'Date';
  String get passengers => _fr ? 'Passagers' : 'Passengers';
  String get noTripsFound =>
      _fr ? 'Aucun voyage trouvé pour cet itinéraire' : 'No trips found for this route';
  String get findBus => _fr ? 'Trouver un Bus' : 'Find a Bus';
  String get searchResults => _fr ? 'Résultats de Recherche' : 'Search Results';
  String get tripsFound => _fr ? 'voyages trouvés' : 'trips found';
  String get tripFound => _fr ? 'voyage trouvé' : 'trip found';
  String get selectDate => _fr ? 'Sélectionner une Date' : 'Select Date';
  String get selectPassengers =>
      _fr ? 'Nombre de Passagers' : 'Number of Passengers';
  String get applyFilters => _fr ? 'Appliquer les Filtres' : 'Apply Filters';
  String get clearFilters =>
      _fr ? 'Effacer les Filtres' : 'Clear Filters';

  // ── Booking ──────────────────────────────────────────────────────────────────
  String get bookNow => _fr ? 'Réserver' : 'Book Now';
  String get confirmBooking =>
      _fr ? 'Confirmer la Réservation' : 'Confirm Booking';
  String get passengerDetails =>
      _fr ? 'Détails du Passager' : 'Passenger Details';
  String get paymentMethod => _fr ? 'Mode de Paiement' : 'Payment Method';
  String get tmoney => 'T-Money';
  String get flooz => 'Flooz';
  String get bankTransfer =>
      _fr ? 'Virement Bancaire' : 'Bank Transfer';
  String get totalPrice => _fr ? 'Prix Total' : 'Total Price';
  String get bookingConfirmed =>
      _fr ? 'Réservation Confirmée !' : 'Booking Confirmed!';
  String get tripDetails => _fr ? 'Détails du Voyage' : 'Trip Details';
  String get departure => _fr ? 'Départ' : 'Departure';
  String get arrival => _fr ? 'Arrivée' : 'Arrival';
  String get duration => _fr ? 'Durée' : 'Duration';
  String get availableSeats =>
      _fr ? 'Places Disponibles' : 'Available Seats';
  String get amenities => _fr ? 'Équipements' : 'Amenities';
  String get cancelBooking =>
      _fr ? 'Annuler la Réservation' : 'Cancel Booking';
  String get bookingHistory =>
      _fr ? 'Historique des Réservations' : 'Booking History';
  String get price => _fr ? 'Prix' : 'Price';
  String get perPerson => _fr ? 'par personne' : 'per person';

  // ── Tickets ──────────────────────────────────────────────────────────────────
  String get active => _fr ? 'Actif' : 'Active';
  String get used => _fr ? 'Utilisé' : 'Used';
  String get cancelled => _fr ? 'Annulé' : 'Cancelled';
  String get ticketCode => _fr ? 'Code Billet' : 'Ticket Code';
  String get downloadPdf => _fr ? 'Télécharger PDF' : 'Download PDF';
  String get shareTicket => _fr ? 'Partager le Billet' : 'Share Ticket';
  String get noTickets => _fr ? 'Aucun billet pour le moment' : 'No tickets yet';
  String get bookFirstTrip =>
      _fr ? 'Réservez votre premier voyage' : 'Book your first trip';
  String get showQrCode => _fr ? 'Afficher le Code QR' : 'Show QR Code';
  String get scanAtStation =>
      _fr ? 'Scannez ce code à la gare routière' : 'Scan this code at the bus station';

  // ── Profile ──────────────────────────────────────────────────────────────────
  String get myProfileTitle => _fr ? 'Mon Profil' : 'My Profile';
  String get upgradeToPremium =>
      _fr ? 'Passer Premium' : 'Upgrade to Premium';
  String get editProfile => _fr ? 'Modifier le Profil' : 'Edit Profile';
  String get saveChanges => _fr ? 'Enregistrer' : 'Save Changes';
  String get member => _fr ? 'Membre' : 'Member';
  String get totalBookings =>
      _fr ? 'Réservations Totales' : 'Total Bookings';
  String get traveller => _fr ? 'Voyageur' : 'Traveller';

  // ── Notifications ────────────────────────────────────────────────────────────
  String get notificationsTitle =>
      _fr ? 'Notifications' : 'Notifications';
  String get noNotifications =>
      _fr ? 'Aucune notification pour le moment' : 'No notifications yet';
  String get markAllRead =>
      _fr ? 'Tout marquer comme lu' : 'Mark all as read';
  String get newNotification =>
      _fr ? 'Nouvelle notification' : 'New notification';

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle => _fr ? 'Paramètres' : 'Settings';
  String get general => _fr ? 'Général' : 'General';
  String get language => _fr ? 'Langue' : 'Language';
  String get about => _fr ? 'À Propos' : 'About';
  String get privacyPolicy =>
      _fr ? 'Politique de Confidentialité' : 'Privacy Policy';
  String get termsConditions =>
      _fr ? 'Conditions Générales' : 'Terms & Conditions';
  String get appVersion => _fr ? "Version de l'App" : 'App Version';
  String get faq => _fr ? 'Questions Fréquentes' : 'FAQ';
  String get contactUs => _fr ? 'Nous Contacter' : 'Contact Us';
  String get frequentlyAskedQuestions =>
      _fr ? 'Questions Fréquentes' : 'Frequently Asked Questions';

  // ── Settings – FAQ ────────────────────────────────────────────────────────────
  List<(String, String)> get faqItems => _fr
      ? [
          (
            'Comment réserver un voyage ?',
            "Recherchez votre itinéraire dans l'onglet Rechercher. Sélectionnez un voyage, renseignez vos informations passager, choisissez un mode de paiement et confirmez. Vous recevrez votre billet instantanément.",
          ),
          (
            'Puis-je annuler ma réservation ?',
            "Oui. Rendez-vous dans Mes Billets, ouvrez le billet que vous souhaitez annuler et appuyez sur « Annuler la Réservation ». Les remboursements sont traités sous 3 à 5 jours ouvrés selon votre mode de paiement.",
          ),
          (
            'Quels modes de paiement sont acceptés ?',
            'Nous acceptons T-Money, Flooz et le virement bancaire. Tous les paiements sont traités de manière sécurisée.',
          ),
          (
            'Comment obtenir mon billet ?',
            'Votre billet est disponible immédiatement après la réservation dans l\'onglet « Billets ». Vous pouvez le télécharger en PDF ou présenter le code QR à la gare routière.',
          ),
          (
            'Quelles villes dessert QuickTZ ?',
            'Nous couvrons Lomé, Kara, Sokodé, Dapaong, Atakpamé, Bassar, Notsé, Tsévié, Bafilo, Niamtougou, Badou, Aného, Vogan et Tabligbo.',
          ),
          (
            'Comment fonctionne le chatbot IA ?',
            'Le chatbot QuickTZ peut rechercher des voyages, comparer les agences et même réserver votre billet — tout par conversation. Décrivez simplement ce dont vous avez besoin en langage naturel.',
          ),
        ]
      : [
          (
            'How do I book a trip?',
            "Search for your route using the Search tab. Select a trip, fill in your passenger details, choose a payment method and confirm. You'll receive a ticket instantly.",
          ),
          (
            'Can I cancel my booking?',
            "Yes. Go to My Tickets, open the ticket you want to cancel, and tap \"Cancel Booking\". Refunds are processed within 3–5 business days depending on your payment method.",
          ),
          (
            'What payment methods are accepted?',
            'We accept T-Money, Flooz, and bank transfer. All payments are processed securely.',
          ),
          (
            'How do I get my ticket?',
            'Your ticket is available immediately after booking under the "Tickets" tab. You can download it as a PDF or show the QR code at the bus station.',
          ),
          (
            'What cities does QuickTZ serve?',
            'We cover Lomé, Kara, Sokodé, Dapaong, Atakpamé, Bassar, Notsé, Tsévié, Bafilo, Niamtougou, Badou, Aného, Vogan, and Tabligbo.',
          ),
          (
            'How does the AI chatbot work?',
            'The QuickTZ AI can search for trips, compare agencies, and even book your ticket — all through conversation. Just describe what you need in plain language.',
          ),
        ];

  // ── Settings – Legal ──────────────────────────────────────────────────────────
  String get privacyPolicyContent => _fr ? _kPrivacyFr : _kPrivacyEn;
  String get termsContent => _fr ? _kTermsFr : _kTermsEn;

  // ── Errors ───────────────────────────────────────────────────────────────────
  String get networkError =>
      _fr ? 'Erreur réseau. Veuillez réessayer.' : 'Network error. Please try again.';
  String get invalidCredentials =>
      _fr ? 'Email/téléphone ou mot de passe invalide.' : 'Invalid email/phone or password.';
  String get required => _fr ? 'Ce champ est obligatoire' : 'This field is required';

  // ── Common actions ────────────────────────────────────────────────────────────
  String get cancel => _fr ? 'Annuler' : 'Cancel';
  String get confirm => _fr ? 'Confirmer' : 'Confirm';
  String get edit => _fr ? 'Modifier' : 'Edit';
  String get back => _fr ? 'Retour' : 'Back';
  String get next => _fr ? 'Suivant' : 'Next';
  String get done => _fr ? 'Terminer' : 'Done';
  String get close => _fr ? 'Fermer' : 'Close';
  String get retry => _fr ? 'Réessayer' : 'Retry';
  String get yes => _fr ? 'Oui' : 'Yes';
  String get no => _fr ? 'Non' : 'No';
  String get ok => 'OK';

  // ── Chat ─────────────────────────────────────────────────────────────────────
  String get chatHistory => _fr ? 'Historique des Conversations' : 'Chat History';
  String get noHistory => _fr ? 'Aucune conversation précédente' : 'No previous conversations';
  String get clearHistory => _fr ? "Effacer l'historique" : 'Clear History';
  String get typeMessage => _fr ? 'Écrivez un message…' : 'Type a message…';
}

// ── Provider ──────────────────────────────────────────────────────────────────

final l10nProvider = Provider<AppL10n>((ref) {
  final lang = ref.watch(localeProvider);
  return AppL10n(lang);
});

// ── Legal content ─────────────────────────────────────────────────────────────

const _kPrivacyEn = '''
Last updated: May 2025

QuickTZ ("we", "our", or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use the QuickTZ mobile application.

1. Information We Collect
We collect information you provide directly when you create an account, book a trip, or contact us. This includes your name, phone number, email address, and payment information.

2. How We Use Your Information
We use your personal data to:
• Process and confirm your trip bookings
• Send booking confirmations and trip reminders
• Improve the app and personalise your experience
• Comply with legal obligations

3. Data Sharing
We do not sell your personal data. We may share your information with:
• Bus agencies to fulfil your bookings
• Payment processors to complete transactions
• Legal authorities if required by law

4. Data Security
We implement industry-standard security measures including encrypted storage and secure HTTPS connections to protect your data.

5. Your Rights
You have the right to access, correct, or delete your personal data. Contact us at privacy@quicktz.com for any requests.

6. Cookies & Analytics
The app may collect anonymised usage data to improve performance and user experience.

7. Contact
For privacy-related questions: privacy@quicktz.com
''';

const _kPrivacyFr = '''
Dernière mise à jour : Mai 2025

QuickTZ (« nous », « notre ») s'engage à protéger vos informations personnelles. Cette Politique de Confidentialité explique comment nous collectons, utilisons et protégeons vos données lorsque vous utilisez l'application mobile QuickTZ.

1. Informations Collectées
Nous collectons les informations que vous fournissez directement lors de la création d'un compte, de la réservation d'un voyage ou lorsque vous nous contactez. Cela inclut votre nom, numéro de téléphone, adresse e-mail et informations de paiement.

2. Utilisation de Vos Informations
Nous utilisons vos données personnelles pour :
• Traiter et confirmer vos réservations de voyage
• Envoyer des confirmations de réservation et rappels de voyage
• Améliorer l'application et personnaliser votre expérience
• Respecter les obligations légales

3. Partage des Données
Nous ne vendons pas vos données personnelles. Nous pouvons partager vos informations avec :
• Les agences de bus pour exécuter vos réservations
• Les processeurs de paiement pour compléter les transactions
• Les autorités légales si requis par la loi

4. Sécurité des Données
Nous mettons en œuvre des mesures de sécurité conformes aux normes de l'industrie, incluant le stockage chiffré et des connexions HTTPS sécurisées.

5. Vos Droits
Vous avez le droit d'accéder, de corriger ou de supprimer vos données personnelles. Contactez-nous à privacy@quicktz.com pour toute demande.

6. Cookies & Analytiques
L'application peut collecter des données d'utilisation anonymisées pour améliorer les performances et l'expérience utilisateur.

7. Contact
Pour toute question relative à la vie privée : privacy@quicktz.com
''';

const _kTermsEn = '''
Last updated: May 2025

These Terms & Conditions govern your use of the QuickTZ mobile application and the services provided through it.

1. Acceptance of Terms
By using QuickTZ, you agree to these terms. If you do not agree, please do not use the app.

2. Booking Policy
• Bookings are confirmed only after successful payment
• Ticket prices are displayed in XOF (CFA Francs) and are inclusive of all fees
• Seats are allocated on a first-come, first-served basis

3. Cancellation & Refunds
• Cancellations made more than 24 hours before departure are eligible for a full refund
• Cancellations within 24 hours of departure are non-refundable
• Refunds are processed within 3–5 business days

4. User Responsibilities
• You are responsible for providing accurate passenger information
• You must present a valid ticket (digital or printed) at boarding
• QuickTZ is not liable for missed trips due to incorrect information

5. Agency Relationships
QuickTZ acts as a booking platform. The bus agencies are independent operators responsible for service delivery, schedules, and on-board experience.

6. Limitation of Liability
QuickTZ is not liable for delays, cancellations, or service failures caused by the bus agencies or events beyond our control.

7. Changes to Terms
We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of the updated terms.

8. Contact
For legal inquiries: legal@quicktz.com
''';

const _kTermsFr = '''
Dernière mise à jour : Mai 2025

Ces Conditions Générales régissent votre utilisation de l'application mobile QuickTZ et des services fournis par celle-ci.

1. Acceptation des Conditions
En utilisant QuickTZ, vous acceptez ces conditions. Si vous n'êtes pas d'accord, veuillez ne pas utiliser l'application.

2. Politique de Réservation
• Les réservations sont confirmées uniquement après un paiement réussi
• Les prix des billets sont affichés en XOF (Francs CFA) et incluent tous les frais
• Les places sont attribuées selon le principe du premier arrivé, premier servi

3. Annulation & Remboursements
• Les annulations effectuées plus de 24 heures avant le départ donnent droit à un remboursement intégral
• Les annulations dans les 24 heures précédant le départ ne sont pas remboursables
• Les remboursements sont traités sous 3 à 5 jours ouvrés

4. Responsabilités de l'Utilisateur
• Vous êtes responsable de fournir des informations passager exactes
• Vous devez présenter un billet valide (numérique ou imprimé) à l'embarquement
• QuickTZ n'est pas responsable des voyages manqués en raison d'informations incorrectes

5. Relations avec les Agences
QuickTZ agit en tant que plateforme de réservation. Les agences de bus sont des opérateurs indépendants responsables de la prestation de service, des horaires et de l'expérience à bord.

6. Limitation de Responsabilité
QuickTZ n'est pas responsable des retards, annulations ou défaillances de service causés par les agences de bus ou des événements hors de notre contrôle.

7. Modifications des Conditions
Nous nous réservons le droit de modifier ces conditions à tout moment. L'utilisation continue de l'application constitue l'acceptation des conditions mises à jour.

8. Contact
Pour toute question juridique : legal@quicktz.com
''';
