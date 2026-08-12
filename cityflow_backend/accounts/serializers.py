"""
accounts.serializers — refonte pour :
  - Créer un compte : nom complet (un seul champ dans la maquette, éclaté en
    first_name/last_name côté modèle), email, téléphone, mot de passe
  - Bienvenue/Connexion : "Email ou téléphone" — un seul champ, résolu vers
    l'utilisateur correspondant avant l'authentification JWT standard
  - Profil : lecture/écriture des infos perso, lieux, préférences
"""
from django.contrib.auth.password_validation import validate_password
from django.db.models import Q
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import User, SavedPlace, UserPreferences, ZoneSurveillee


class CityFlowTokenSerializer(TokenObtainPairSerializer):
    """Connexion par email OU téléphone (écran Bienvenue), pas par username."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields.pop(self.username_field, None)
        self.fields['identifiant'] = serializers.CharField()

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        return token

    def validate(self, attrs):
        identifiant = attrs.pop('identifiant', '').strip()
        try:
            user = User.objects.get(Q(email__iexact=identifiant) | Q(telephone=identifiant))
        except User.DoesNotExist:
            raise serializers.ValidationError(
                {'identifiant': "Aucun compte associé à cet email ou ce téléphone."}
            )
        attrs[self.username_field] = user.get_username()
        data = super().validate(attrs)
        data['role'] = self.user.role
        data['user'] = UserSerializer(self.user).data
        return data


class RegisterSerializer(serializers.ModelSerializer):
    nom_complet = serializers.CharField(write_only=True, max_length=150)
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = User
        fields = ('nom_complet', 'email', 'telephone', 'password')

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Un compte existe déjà avec cet email.")
        return value

    def validate_telephone(self, value):
        if value and User.objects.filter(telephone=value).exists():
            raise serializers.ValidationError("Un compte existe déjà avec ce téléphone.")
        return value

    def create(self, validated_data):
        nom_complet = validated_data.pop('nom_complet').strip()
        prenom, _, nom = nom_complet.partition(' ')
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            telephone=validated_data.get('telephone') or None,
            first_name=prenom,
            last_name=nom,
            password=validated_data['password'],
            role='citoyen',
        )
        UserPreferences.objects.create(user=user)
        return user


class UserSerializer(serializers.ModelSerializer):
    """Lecture — écran Profil (en-tête + informations personnelles)."""
    nom_complet = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'nom_complet', 'email', 'telephone', 'adresse', 'avatar', 'role', 'zone')

    def get_nom_complet(self, obj):
        return obj.get_full_name() or obj.username


class ProfileUpdateSerializer(serializers.ModelSerializer):
    """Écriture — édition des informations personnelles depuis le Profil."""

    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'email', 'telephone', 'adresse', 'avatar')


class SavedPlaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedPlace
        fields = ('id', 'type', 'label', 'adresse', 'latitude', 'longitude', 'created_at')
        read_only_fields = ('id', 'created_at')


class UserPreferencesSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserPreferences
        fields = ('notifications_actives', 'mode_transport', 'eviter_zones_inondables', 'eviter_peages')


class ZoneSurveilleeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ZoneSurveillee
        fields = ('id', 'zone', 'created_at')
        read_only_fields = ('id', 'created_at')
