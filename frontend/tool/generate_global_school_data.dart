import 'dart:convert';
import 'dart:io';

void main() {
  print('=== Generating Global School Management System Dynamic JSON Datasets ===');

  // ---------------------------------------------------------------------------
  // 1. BASE USERS
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> users = [
    // Executive Administrators
    {
      'id': 'usr-adm-001',
      'email': 'ananya.deshmukh@edupulse.edu.in',
      'phone_number': '+91 98450 11001',
      'password_hash': r'$2b$12$eX8A91kM...ananya_hash',
      'user_role': 'ADMIN',
      'first_name': 'Ananya',
      'last_name': 'Deshmukh',
      'profile_photo_url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1975-08-14',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:15:00.000Z',
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-17T08:15:00.000Z'
    },
    {
      'id': 'usr-adm-002',
      'email': 'rajesh.nair@edupulse.edu.in',
      'phone_number': '+91 98450 11002',
      'password_hash': r'$2b$12$eX8A91kM...rajesh_hash',
      'user_role': 'ADMIN',
      'first_name': 'Rajesh',
      'last_name': 'Nair',
      'profile_photo_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1978-03-22',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T17:45:00.000Z',
      'created_at': '2024-02-01T09:00:00.000Z',
      'updated_at': '2026-10-16T17:45:00.000Z'
    },
    {
      'id': 'usr-adm-003',
      'email': 'arvind.swamy@edupulse.edu.in',
      'phone_number': '+91 98450 11003',
      'password_hash': r'$2b$12$eX8A91kM...arvind_hash',
      'user_role': 'ADMIN',
      'first_name': 'Arvind',
      'last_name': 'Swamy',
      'profile_photo_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1985-11-05',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T07:30:00.000Z',
      'created_at': '2024-03-15T09:00:00.000Z',
      'updated_at': '2026-10-17T07:30:00.000Z'
    },

    // Admissions Officers
    {
      'id': 'usr-admissions-101',
      'email': 'sunita.rao@edupulse.edu.in',
      'phone_number': '+91 98450 22001',
      'password_hash': r'$2b$12$eX8A91kM...sunita_hash',
      'user_role': 'ADMISSIONS',
      'first_name': 'Sunita',
      'last_name': 'Rao',
      'profile_photo_url': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1986-06-18',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:45:00.000Z',
      'created_at': '2024-04-10T09:00:00.000Z',
      'updated_at': '2026-10-17T08:45:00.000Z'
    },
    {
      'id': 'usr-admissions-102',
      'email': 'pooja.verma@edupulse.edu.in',
      'phone_number': '+91 98450 22002',
      'password_hash': r'$2b$12$eX8A91kM...pooja_hash',
      'user_role': 'ADMISSIONS',
      'first_name': 'Pooja',
      'last_name': 'Verma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1992-09-24',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T16:20:00.000Z',
      'created_at': '2024-06-01T09:00:00.000Z',
      'updated_at': '2026-10-16T16:20:00.000Z'
    },

    // Finance & Accounts Officers
    {
      'id': 'usr-fin-201',
      'email': 'ramanathan.kr@edupulse.edu.in',
      'phone_number': '+91 98450 33001',
      'password_hash': r'$2b$12$eX8A91kM...ramanathan_hash',
      'user_role': 'FINANCE',
      'first_name': 'K. R.',
      'last_name': 'Ramanathan',
      'profile_photo_url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1976-12-30',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T09:10:00.000Z',
      'created_at': '2024-01-15T09:00:00.000Z',
      'updated_at': '2026-10-17T09:10:00.000Z'
    },
    {
      'id': 'usr-fin-202',
      'email': 'meenakshi.sundaram@edupulse.edu.in',
      'phone_number': '+91 98450 33002',
      'password_hash': r'$2b$12$eX8A91kM...meenakshi_hash',
      'user_role': 'FINANCE',
      'first_name': 'Meenakshi',
      'last_name': 'Sundaram',
      'profile_photo_url': 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1983-05-14',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T18:00:00.000Z',
      'created_at': '2024-03-01T09:00:00.000Z',
      'updated_at': '2026-10-16T18:00:00.000Z'
    },

    // Faculty / Teachers
    {
      'id': 'usr-tch-301',
      'email': 'rajeshwari.swaminathan@edupulse.edu.in',
      'phone_number': '+91 98450 44001',
      'password_hash': r'$2b$12$eX8A91kM...rajeshwari_hash',
      'user_role': 'TEACHER',
      'first_name': 'Rajeshwari',
      'last_name': 'Swaminathan',
      'profile_photo_url': 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1982-04-12',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:00:00.000Z',
      'created_at': '2024-06-15T09:00:00.000Z',
      'updated_at': '2026-10-17T08:00:00.000Z'
    },
    {
      'id': 'usr-tch-302',
      'email': 'vikramaditya.sen@edupulse.edu.in',
      'phone_number': '+91 98450 44002',
      'password_hash': r'$2b$12$eX8A91kM...vikram_hash',
      'user_role': 'TEACHER',
      'first_name': 'Vikramaditya',
      'last_name': 'Sen',
      'profile_photo_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1979-07-28',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:30:00.000Z',
      'created_at': '2024-06-15T09:00:00.000Z',
      'updated_at': '2026-10-17T08:30:00.000Z'
    },
    {
      'id': 'usr-tch-303',
      'email': 'priya.nambiar@edupulse.edu.in',
      'phone_number': '+91 98450 44003',
      'password_hash': r'$2b$12$eX8A91kM...priya_hash',
      'user_role': 'TEACHER',
      'first_name': 'Priya',
      'last_name': 'Nambiar',
      'profile_photo_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1987-10-03',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:10:00.000Z',
      'created_at': '2024-07-01T09:00:00.000Z',
      'updated_at': '2026-10-17T08:10:00.000Z'
    },
    {
      'id': 'usr-tch-304',
      'email': 'amit.chatterjee@edupulse.edu.in',
      'phone_number': '+91 98450 44004',
      'password_hash': r'$2b$12$eX8A91kM...amit_hash',
      'user_role': 'TEACHER',
      'first_name': 'Amit',
      'last_name': 'Chatterjee',
      'profile_photo_url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1984-01-19',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T15:20:00.000Z',
      'created_at': '2024-07-01T09:00:00.000Z',
      'updated_at': '2026-10-16T15:20:00.000Z'
    },
    {
      'id': 'usr-tch-305',
      'email': 'kavita.sharma@edupulse.edu.in',
      'phone_number': '+91 98450 44005',
      'password_hash': r'$2b$12$eX8A91kM...kavita_hash',
      'user_role': 'TEACHER',
      'first_name': 'Kavita',
      'last_name': 'Sharma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1988-09-11',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:25:00.000Z',
      'created_at': '2024-07-15T09:00:00.000Z',
      'updated_at': '2026-10-17T08:25:00.000Z'
    },
    {
      'id': 'usr-tch-306',
      'email': 'gurpreet.singh@edupulse.edu.in',
      'phone_number': '+91 98450 44006',
      'password_hash': r'$2b$12$eX8A91kM...gurpreet_hash',
      'user_role': 'TEACHER',
      'first_name': 'Gurpreet',
      'last_name': 'Singh',
      'profile_photo_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1986-02-14',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T16:00:00.000Z',
      'created_at': '2024-08-01T09:00:00.000Z',
      'updated_at': '2026-10-16T16:00:00.000Z'
    },

    // Operational & Support Staff Users
    {
      'id': 'usr-sup-401',
      'email': 'geetha.krishnan@edupulse.edu.in',
      'phone_number': '+91 98450 55001',
      'password_hash': r'$2b$12$eX8A91kM...geetha_hash',
      'user_role': 'ADMIN',
      'first_name': 'Geetha',
      'last_name': 'Krishnan',
      'profile_photo_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1980-12-04',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:00:00.000Z',
      'created_at': '2024-05-01T09:00:00.000Z',
      'updated_at': '2026-10-17T08:00:00.000Z'
    },
    {
      'id': 'usr-sup-402',
      'email': 'subhash.bose@edupulse.edu.in',
      'phone_number': '+91 98450 55002',
      'password_hash': r'$2b$12$eX8A91kM...subhash_hash',
      'user_role': 'ADMIN',
      'first_name': 'Subhash',
      'last_name': 'Bose',
      'profile_photo_url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1985-04-18',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T17:15:00.000Z',
      'created_at': '2024-05-15T09:00:00.000Z',
      'updated_at': '2026-10-16T17:15:00.000Z'
    },
    {
      'id': 'usr-sup-403',
      'email': 'harpreet.singh@edupulse.edu.in',
      'phone_number': '+91 98450 55003',
      'password_hash': r'$2b$12$eX8A91kM...harpreet_hash',
      'user_role': 'ADMIN',
      'first_name': 'Harpreet',
      'last_name': 'Singh',
      'profile_photo_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1979-11-23',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T06:30:00.000Z',
      'created_at': '2024-06-01T09:00:00.000Z',
      'updated_at': '2026-10-17T06:30:00.000Z'
    },
    {
      'id': 'usr-sup-404',
      'email': 'sharda.devi@edupulse.edu.in',
      'phone_number': '+91 98450 55004',
      'password_hash': r'$2b$12$eX8A91kM...sharda_hash',
      'user_role': 'ADMIN',
      'first_name': 'Sharda',
      'last_name': 'Devi',
      'profile_photo_url': 'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1974-08-19',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T21:00:00.000Z',
      'created_at': '2024-06-15T09:00:00.000Z',
      'updated_at': '2026-10-16T21:00:00.000Z'
    },
    {
      'id': 'usr-sup-405',
      'email': 'mary.joseph@edupulse.edu.in',
      'phone_number': '+91 98450 55005',
      'password_hash': r'$2b$12$eX8A91kM...mary_hash',
      'user_role': 'ADMIN',
      'first_name': 'Sister Mary',
      'last_name': 'Joseph',
      'profile_photo_url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1981-01-25',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T07:45:00.000Z',
      'created_at': '2024-07-01T09:00:00.000Z',
      'updated_at': '2026-10-17T07:45:00.000Z'
    },
    {
      'id': 'usr-sup-406',
      'email': 'balwant.singh@edupulse.edu.in',
      'phone_number': '+91 98450 55006',
      'password_hash': r'$2b$12$eX8A91kM...balwant_hash',
      'user_role': 'ADMIN',
      'first_name': 'Balwant',
      'last_name': 'Singh',
      'profile_photo_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1970-05-10',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T06:00:00.000Z',
      'created_at': '2024-07-01T09:00:00.000Z',
      'updated_at': '2026-10-17T06:00:00.000Z'
    },

    // Students
    {
      'id': 'usr-std-501',
      'email': 'aarav.sharma@student.edupulse.edu.in',
      'phone_number': '+91 98101 66001',
      'password_hash': r'$2b$12$eX8A91kM...aarav_hash',
      'user_role': 'STUDENT',
      'first_name': 'Aarav',
      'last_name': 'Sharma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '2008-11-10',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T08:15:00.000Z',
      'created_at': '2024-06-01T08:00:00.000Z',
      'updated_at': '2026-10-17T08:15:00.000Z'
    },
    {
      'id': 'usr-std-502',
      'email': 'diya.patel@student.edupulse.edu.in',
      'phone_number': '+91 98101 66002',
      'password_hash': r'$2b$12$eX8A91kM...diya_hash',
      'user_role': 'STUDENT',
      'first_name': 'Diya',
      'last_name': 'Patel',
      'profile_photo_url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '2008-07-22',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T19:30:00.000Z',
      'created_at': '2024-06-01T08:00:00.000Z',
      'updated_at': '2026-10-16T19:30:00.000Z'
    },
    {
      'id': 'usr-std-503',
      'email': 'rohan.gupta@student.edupulse.edu.in',
      'phone_number': '+91 98101 66003',
      'password_hash': r'$2b$12$eX8A91kM...rohan_hash',
      'user_role': 'STUDENT',
      'first_name': 'Rohan',
      'last_name': 'Gupta',
      'profile_photo_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '2008-04-15',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T07:50:00.000Z',
      'created_at': '2024-06-01T08:00:00.000Z',
      'updated_at': '2026-10-17T07:50:00.000Z'
    },
    {
      'id': 'usr-std-504',
      'email': 'ananya.reddy@student.edupulse.edu.in',
      'phone_number': '+91 98101 66004',
      'password_hash': r'$2b$12$eX8A91kM...ananya_r_hash',
      'user_role': 'STUDENT',
      'first_name': 'Ananya',
      'last_name': 'Reddy',
      'profile_photo_url': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '2007-09-05',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T20:10:00.000Z',
      'created_at': '2024-06-01T08:00:00.000Z',
      'updated_at': '2026-10-16T20:10:00.000Z'
    },
    {
      'id': 'usr-std-505',
      'email': 'kabir.mehta@student.edupulse.edu.in',
      'phone_number': '+91 98101 66005',
      'password_hash': r'$2b$12$eX8A91kM...kabir_hash',
      'user_role': 'STUDENT',
      'first_name': 'Kabir',
      'last_name': 'Mehta',
      'profile_photo_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '2006-12-14',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T09:00:00.000Z',
      'created_at': '2024-06-01T08:00:00.000Z',
      'updated_at': '2026-10-17T09:00:00.000Z'
    },
    {
      'id': 'usr-std-506',
      'email': 'siddharth.varma@student.edupulse.edu.in',
      'phone_number': '+91 98101 66006',
      'password_hash': r'$2b$12$eX8A91kM...sid_hash',
      'user_role': 'STUDENT',
      'first_name': 'Siddharth',
      'last_name': 'Varma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '2008-02-18',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-14T11:20:00.000Z',
      'created_at': '2024-06-01T08:00:00.000Z',
      'updated_at': '2026-10-14T11:20:00.000Z'
    },

    // Parents
    {
      'id': 'usr-par-601',
      'email': 'ramesh.sharma@gmail.com',
      'phone_number': '+91 98765 77001',
      'password_hash': r'$2b$12$eX8A91kM...ramesh_hash',
      'user_role': 'PARENT',
      'first_name': 'Ramesh',
      'last_name': 'Sharma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1976-05-12',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T21:40:00.000Z',
      'created_at': '2024-06-01T08:30:00.000Z',
      'updated_at': '2026-10-16T21:40:00.000Z'
    },
    {
      'id': 'usr-par-602',
      'email': 'sunita.sharma@gmail.com',
      'phone_number': '+91 98765 77002',
      'password_hash': r'$2b$12$eX8A91kM...sunita_s_hash',
      'user_role': 'PARENT',
      'first_name': 'Sunita',
      'last_name': 'Sharma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
      'gender': 'FEMALE',
      'date_of_birth': '1979-08-20',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-15T18:10:00.000Z',
      'created_at': '2024-06-01T08:30:00.000Z',
      'updated_at': '2026-10-15T18:10:00.000Z'
    },
    {
      'id': 'usr-par-603',
      'email': 'bhavin.patel@gmail.com',
      'phone_number': '+91 98765 77003',
      'password_hash': r'$2b$12$eX8A91kM...bhavin_hash',
      'user_role': 'PARENT',
      'first_name': 'Bhavin',
      'last_name': 'Patel',
      'profile_photo_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1975-10-08',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T19:15:00.000Z',
      'created_at': '2024-06-01T08:30:00.000Z',
      'updated_at': '2026-10-16T19:15:00.000Z'
    },
    {
      'id': 'usr-par-604',
      'email': 'sanjay.gupta@gmail.com',
      'phone_number': '+91 98765 77004',
      'password_hash': r'$2b$12$eX8A91kM...sanjay_hash',
      'user_role': 'PARENT',
      'first_name': 'Sanjay',
      'last_name': 'Gupta',
      'profile_photo_url': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1973-03-17',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-17T07:10:00.000Z',
      'created_at': '2024-06-01T08:30:00.000Z',
      'updated_at': '2026-10-17T07:10:00.000Z'
    },
    {
      'id': 'usr-par-605',
      'email': 'venkat.reddy@gmail.com',
      'phone_number': '+91 98765 77005',
      'password_hash': r'$2b$12$eX8A91kM...venkat_hash',
      'user_role': 'PARENT',
      'first_name': 'Venkat',
      'last_name': 'Reddy',
      'profile_photo_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1972-12-01',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-16T22:00:00.000Z',
      'created_at': '2024-06-01T08:30:00.000Z',
      'updated_at': '2026-10-16T22:00:00.000Z'
    },
    {
      'id': 'usr-par-606',
      'email': 'manish.varma@gmail.com',
      'phone_number': '+91 98765 77006',
      'password_hash': r'$2b$12$eX8A91kM...manish_hash',
      'user_role': 'PARENT',
      'first_name': 'Manish',
      'last_name': 'Varma',
      'profile_photo_url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
      'gender': 'MALE',
      'date_of_birth': '1974-06-25',
      'status': 'ACTIVE',
      'last_login_at': '2026-10-14T10:45:00.000Z',
      'created_at': '2024-06-01T08:30:00.000Z',
      'updated_at': '2026-10-14T10:45:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 2. USER-SPECIFIC PROFILE MODELS
  // ---------------------------------------------------------------------------

  // D. AdminProfile
  final List<Map<String, dynamic>> adminProfiles = [
    {
      'id': 'adm-prof-001',
      'user_id': 'usr-adm-001',
      'employee_id': 'EMP-ADM-001',
      'admin_title': 'PRINCIPAL',
      'is_primary_admin': true,
      'access_tier': 'TIER_1',
      'can_override_attendance': true,
      'can_approve_report_cards': true,
      'can_approve_clearances': true
    },
    {
      'id': 'adm-prof-002',
      'user_id': 'usr-adm-002',
      'employee_id': 'EMP-ADM-002',
      'admin_title': 'DIRECTOR',
      'is_primary_admin': false,
      'access_tier': 'TIER_1',
      'can_override_attendance': true,
      'can_approve_report_cards': true,
      'can_approve_clearances': true
    },
    {
      'id': 'adm-prof-003',
      'user_id': 'usr-adm-003',
      'employee_id': 'EMP-ADM-003',
      'admin_title': 'IT_ADMIN',
      'is_primary_admin': false,
      'access_tier': 'TIER_2',
      'can_override_attendance': true,
      'can_approve_report_cards': false,
      'can_approve_clearances': false
    }
  ];

  // E. AdmissionsOfficerProfile
  final List<Map<String, dynamic>> admissionsOfficerProfiles = [
    {
      'id': 'adm-off-101',
      'user_id': 'usr-admissions-101',
      'staff_id': 'STF-ADM-101',
      'designation': 'Senior Admissions Manager',
      'department': 'Admissions & Student Relations',
      'reporting_admin_id': 'usr-adm-001',
      'joining_date': '2022-04-10',
      'assigned_campaign': 'Admissions-2026-Fall',
      'employment_status': 'ACTIVE',
      'can_issue_id_badges': true
    },
    {
      'id': 'adm-off-102',
      'user_id': 'usr-admissions-102',
      'staff_id': 'STF-ADM-102',
      'designation': 'Front Desk Executive',
      'department': 'Admissions & Front Desk',
      'reporting_admin_id': 'usr-adm-002',
      'joining_date': '2023-06-01',
      'assigned_campaign': 'Admissions-2026-Fall',
      'employment_status': 'ACTIVE',
      'can_issue_id_badges': true
    }
  ];

  // F. FinanceOfficerProfile
  final List<Map<String, dynamic>> financeOfficerProfiles = [
    {
      'id': 'fin-off-201',
      'user_id': 'usr-fin-201',
      'staff_id': 'STF-FIN-201',
      'designation': 'Bursar & Chief Financial Officer',
      'department': 'Finance & Accounts',
      'joining_date': '2021-01-15',
      'employment_status': 'ACTIVE',
      'max_concession_approval_limit': 50000.00,
      'can_reconcile_payments': true
    },
    {
      'id': 'fin-off-202',
      'user_id': 'usr-fin-202',
      'staff_id': 'STF-FIN-202',
      'designation': 'Senior Cashier & Fee Incharge',
      'department': 'Finance & Accounts',
      'joining_date': '2022-03-01',
      'employment_status': 'ACTIVE',
      'max_concession_approval_limit': 15000.00,
      'can_reconcile_payments': true
    }
  ];

  // C. TeacherProfile
  final List<Map<String, dynamic>> teacherProfiles = [
    {
      'id': 'tch-prof-301',
      'user_id': 'usr-tch-301',
      'employee_id': 'EMP-TCH-101',
      'department': 'Mathematics',
      'designation': 'HOD & Senior PGT Mathematics',
      'qualification': 'Ph.D. in Applied Mathematics, M.Sc., B.Ed.',
      'joining_date': '2020-06-15',
      'is_class_incharge': true,
      'casual_leave_quota': 12,
      'medical_leave_quota': 10,
      'casual_leave_balance': 9,
      'medical_leave_balance': 10,
      'work_email': 'rajeshwari.swaminathan@edupulse.edu.in',
      'contact_phone': '+91 98450 44001',
      'employment_status': 'ACTIVE'
    },
    {
      'id': 'tch-prof-302',
      'user_id': 'usr-tch-302',
      'employee_id': 'EMP-TCH-102',
      'department': 'Sciences',
      'designation': 'Senior PGT Physics & Science Coordinator',
      'qualification': 'M.Sc. Physics (Gold Medalist), B.Ed., CSIR-NET',
      'joining_date': '2021-04-01',
      'is_class_incharge': true,
      'casual_leave_quota': 12,
      'medical_leave_quota': 10,
      'casual_leave_balance': 11,
      'medical_leave_balance': 8,
      'work_email': 'vikramaditya.sen@edupulse.edu.in',
      'contact_phone': '+91 98450 44002',
      'employment_status': 'ACTIVE'
    },
    {
      'id': 'tch-prof-303',
      'user_id': 'usr-tch-303',
      'employee_id': 'EMP-TCH-103',
      'department': 'Sciences',
      'designation': 'PGT Chemistry',
      'qualification': 'M.Sc. Organic Chemistry, B.Ed.',
      'joining_date': '2021-07-01',
      'is_class_incharge': false,
      'casual_leave_quota': 12,
      'medical_leave_quota': 10,
      'casual_leave_balance': 12,
      'medical_leave_balance': 10,
      'work_email': 'priya.nambiar@edupulse.edu.in',
      'contact_phone': '+91 98450 44003',
      'employment_status': 'ACTIVE'
    },
    {
      'id': 'tch-prof-304',
      'user_id': 'usr-tch-304',
      'employee_id': 'EMP-TCH-104',
      'department': 'Computer Science',
      'designation': 'HOD Computer Science & AI Labs',
      'qualification': 'M.Tech Computer Science, B.Tech IT',
      'joining_date': '2022-01-10',
      'is_class_incharge': true,
      'casual_leave_quota': 12,
      'medical_leave_quota': 10,
      'casual_leave_balance': 10,
      'medical_leave_balance': 10,
      'work_email': 'amit.chatterjee@edupulse.edu.in',
      'contact_phone': '+91 98450 44004',
      'employment_status': 'ACTIVE'
    },
    {
      'id': 'tch-prof-305',
      'user_id': 'usr-tch-305',
      'employee_id': 'EMP-TCH-105',
      'department': 'Languages',
      'designation': 'Senior TGT English Literature',
      'qualification': 'M.A. English Literature, B.Ed., CELTA',
      'joining_date': '2022-07-15',
      'is_class_incharge': true,
      'casual_leave_quota': 12,
      'medical_leave_quota': 10,
      'casual_leave_balance': 12,
      'medical_leave_balance': 9,
      'work_email': 'kavita.sharma@edupulse.edu.in',
      'contact_phone': '+91 98450 44005',
      'employment_status': 'ACTIVE'
    },
    {
      'id': 'tch-prof-306',
      'user_id': 'usr-tch-306',
      'employee_id': 'EMP-TCH-106',
      'department': 'Humanities',
      'designation': 'Senior TGT Social Science & Civics',
      'qualification': 'M.A. History, B.Ed.',
      'joining_date': '2023-01-05',
      'is_class_incharge': false,
      'casual_leave_quota': 12,
      'medical_leave_quota': 10,
      'casual_leave_balance': 11,
      'medical_leave_balance': 10,
      'work_email': 'gurpreet.singh@edupulse.edu.in',
      'contact_phone': '+91 98450 44006',
      'employment_status': 'ACTIVE'
    }
  ];

  // G. SupportStaffProfile (Operational & Support across school departments)
  final List<Map<String, dynamic>> supportStaffProfiles = [
    {
      'id': 'sup-prof-401',
      'user_id': 'usr-sup-401',
      'staff_id': 'STF-SUP-301',
      'role_type': 'LIBRARIAN',
      'designation': 'Chief Librarian & Information Specialist',
      'department': 'Library',
      'joining_date': '2020-05-01',
      'employment_status': 'ACTIVE',
      'assigned_facility': 'Central Library Block B',
      'clearance_authority': 'LIBRARY'
    },
    {
      'id': 'sup-prof-402',
      'user_id': 'usr-sup-402',
      'staff_id': 'STF-SUP-302',
      'role_type': 'LAB_TECHNICIAN',
      'designation': 'Senior Science & CS Lab Incharge',
      'department': 'Labs & Inventory',
      'joining_date': '2021-05-15',
      'employment_status': 'ACTIVE',
      'assigned_facility': 'Science Block Lab 2 & AI Lab 1',
      'clearance_authority': 'LABS_INVENTORY'
    },
    {
      'id': 'sup-prof-403',
      'user_id': 'usr-sup-403',
      'staff_id': 'STF-SUP-303',
      'role_type': 'TRANSPORT_MANAGER',
      'designation': 'Fleet Manager & Transport In-Charge',
      'department': 'Hostel & Transport',
      'joining_date': '2020-06-01',
      'employment_status': 'ACTIVE',
      'assigned_facility': 'School Bus Depot & Fleet Control',
      'clearance_authority': 'HOSTEL_TRANSPORT'
    },
    {
      'id': 'sup-prof-404',
      'user_id': 'usr-sup-404',
      'staff_id': 'STF-SUP-304',
      'role_type': 'HOSTEL_WARDEN',
      'designation': 'Head Hostel Warden (Girls)',
      'department': 'Hostel & Transport',
      'joining_date': '2021-06-15',
      'employment_status': 'ACTIVE',
      'assigned_facility': 'Sarojini Naidu Girls Hostel',
      'clearance_authority': 'HOSTEL_TRANSPORT'
    },
    {
      'id': 'sup-prof-405',
      'user_id': 'usr-sup-405',
      'staff_id': 'STF-SUP-305',
      'role_type': 'NURSE',
      'designation': 'Resident Medical Officer & Campus Nurse',
      'department': 'Health & Infirmary',
      'joining_date': '2022-07-01',
      'employment_status': 'ACTIVE',
      'assigned_facility': 'Health Clinic Room 102',
      'clearance_authority': null
    },
    {
      'id': 'sup-prof-406',
      'user_id': 'usr-sup-406',
      'staff_id': 'STF-SUP-306',
      'role_type': 'SECURITY_HEAD',
      'designation': 'Chief Security & Surveillance Supervisor',
      'department': 'Campus Security',
      'joining_date': '2020-07-01',
      'employment_status': 'ACTIVE',
      'assigned_facility': 'Main Gate Security Station & CCTV Room',
      'clearance_authority': null
    }
  ];

  // B. ParentProfile
  final List<Map<String, dynamic>> parentProfiles = [
    {
      'id': 'par-prof-601',
      'user_id': 'usr-par-601',
      'residential_address': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
      'preferred_language': 'en',
      'billing_email': 'ramesh.sharma@gmail.com'
    },
    {
      'id': 'par-prof-602',
      'user_id': 'usr-par-602',
      'residential_address': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
      'preferred_language': 'en',
      'billing_email': 'sunita.sharma@gmail.com'
    },
    {
      'id': 'par-prof-603',
      'user_id': 'usr-par-603',
      'residential_address': 'Villa 14, Prestige Silver Oak, Whitefield, Bengaluru 560066',
      'preferred_language': 'en',
      'billing_email': 'bhavin.patel@gmail.com'
    },
    {
      'id': 'par-prof-604',
      'user_id': 'usr-par-604',
      'residential_address': 'Tower 3, Apt 902, Sobha Iris, Outer Ring Road, Bengaluru 560103',
      'preferred_language': 'en',
      'billing_email': 'sanjay.gupta@gmail.com'
    },
    {
      'id': 'par-prof-605',
      'user_id': 'usr-par-605',
      'residential_address': 'Plot 45, Golden Palms Avenue, Koramangala, Bengaluru 560034',
      'preferred_language': 'en',
      'billing_email': 'venkat.reddy@gmail.com'
    },
    {
      'id': 'par-prof-606',
      'user_id': 'usr-par-606',
      'residential_address': 'B-104, Alpine Eco Apartments, Marathahalli, Bengaluru 560037',
      'preferred_language': 'hi',
      'billing_email': 'manish.varma@gmail.com'
    }
  ];

  // ---------------------------------------------------------------------------
  // 3. KEY RELATIONSHIP & MAPPING MODELS
  // ---------------------------------------------------------------------------

  // B. ClassSection
  final List<Map<String, dynamic>> classSections = [
    {
      'id': 'cls-sec-10a',
      'class_name': 'Class 10',
      'section_name': 'A',
      'academic_year': '2026-2027',
      'class_incharge_id': 'tch-prof-301', // Dr. Rajeshwari Swaminathan
      'room_number': 'Room 201'
    },
    {
      'id': 'cls-sec-10b',
      'class_name': 'Class 10',
      'section_name': 'B',
      'academic_year': '2026-2027',
      'class_incharge_id': 'tch-prof-305', // Kavita Sharma
      'room_number': 'Room 202'
    },
    {
      'id': 'cls-sec-11a',
      'class_name': 'Class 11',
      'section_name': 'A',
      'academic_year': '2026-2027',
      'class_incharge_id': 'tch-prof-302', // Vikramaditya Sen
      'room_number': 'Room 301'
    },
    {
      'id': 'cls-sec-12a',
      'class_name': 'Class 12',
      'section_name': 'A',
      'academic_year': '2026-2027',
      'class_incharge_id': 'tch-prof-304', // Amit Chatterjee
      'room_number': 'Room 401'
    }
  ];

  // A. StudentProfile
  final List<Map<String, dynamic>> studentProfiles = [
    {
      'id': 'std-prof-501',
      'user_id': 'usr-std-501',
      'admission_number': 'ADM-2026-0042',
      'roll_number': '10',
      'current_class_id': 'cls-sec-10a',
      'admission_date': '2026-06-15',
      'academic_year': '2026-2027',
      'blood_group': 'B+',
      'emergency_contact_phone': '+91 98765 77001',
      'current_address': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
      'enrollment_status': 'ENROLLED',
      'dob_certificate': 'Aadhaar_Birth_Certificate.pdf',
      'transfer_certificate_id': null,
      'residential_address': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru, Karnataka 560103',
      'id_badge_issued': true
    },
    {
      'id': 'std-prof-502',
      'user_id': 'usr-std-502',
      'admission_number': 'ADM-2026-0043',
      'roll_number': '11',
      'current_class_id': 'cls-sec-10a',
      'admission_date': '2026-06-15',
      'academic_year': '2026-2027',
      'blood_group': 'O+',
      'emergency_contact_phone': '+91 98765 77003',
      'current_address': 'Villa 14, Prestige Silver Oak, Whitefield, Bengaluru 560066',
      'enrollment_status': 'ENROLLED',
      'dob_certificate': 'Diya_BirthCert_Govt.pdf',
      'transfer_certificate_id': null,
      'residential_address': 'Villa 14, Prestige Silver Oak, Whitefield, Bengaluru 560066',
      'id_badge_issued': true
    },
    {
      'id': 'std-prof-503',
      'user_id': 'usr-std-503',
      'admission_number': 'ADM-2026-0044',
      'roll_number': '12',
      'current_class_id': 'cls-sec-10b',
      'admission_date': '2026-06-18',
      'academic_year': '2026-2027',
      'blood_group': 'A+',
      'emergency_contact_phone': '+91 98765 77004',
      'current_address': 'Tower 3, Apt 902, Sobha Iris, Outer Ring Road, Bengaluru 560103',
      'enrollment_status': 'ENROLLED',
      'dob_certificate': 'Rohan_BirthCert_Verified.pdf',
      'transfer_certificate_id': null,
      'residential_address': 'Tower 3, Apt 902, Sobha Iris, Outer Ring Road, Bengaluru 560103',
      'id_badge_issued': true
    },
    {
      'id': 'std-prof-504',
      'user_id': 'usr-std-504',
      'admission_number': 'ADM-2025-0019',
      'roll_number': '05',
      'current_class_id': 'cls-sec-11a',
      'admission_date': '2025-06-10',
      'academic_year': '2026-2027',
      'blood_group': 'AB+',
      'emergency_contact_phone': '+91 98765 77005',
      'current_address': 'Plot 45, Golden Palms Avenue, Koramangala, Bengaluru 560034',
      'enrollment_status': 'ENROLLED',
      'dob_certificate': 'Ananya_DOB_Cert.pdf',
      'transfer_certificate_id': null,
      'residential_address': 'Plot 45, Golden Palms Avenue, Koramangala, Bengaluru 560034',
      'id_badge_issued': true
    },
    {
      'id': 'std-prof-505',
      'user_id': 'usr-std-505',
      'admission_number': 'ADM-2024-0008',
      'roll_number': '02',
      'current_class_id': 'cls-sec-12a',
      'admission_date': '2024-06-12',
      'academic_year': '2026-2027',
      'blood_group': 'O-',
      'emergency_contact_phone': '+91 98765 77001',
      'current_address': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru 560103',
      'enrollment_status': 'ENROLLED',
      'dob_certificate': 'Kabir_DOB_Cert.pdf',
      'transfer_certificate_id': null,
      'residential_address': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru 560103',
      'id_badge_issued': true
    },
    {
      'id': 'std-prof-506',
      'user_id': 'usr-std-506',
      'admission_number': 'ADM-2026-0088',
      'roll_number': '24',
      'current_class_id': 'cls-sec-10a',
      'admission_date': '2026-06-20',
      'academic_year': '2026-2027',
      'blood_group': 'B-',
      'emergency_contact_phone': '+91 98765 77006',
      'current_address': 'B-104, Alpine Eco Apartments, Marathahalli, Bengaluru 560037',
      'enrollment_status': 'DISCONTINUED',
      'dob_certificate': 'Siddharth_DOB_Cert.pdf',
      'transfer_certificate_id': 'tc-cert-901',
      'residential_address': 'B-104, Alpine Eco Apartments, Marathahalli, Bengaluru 560037',
      'id_badge_issued': true
    }
  ];

  // A. StudentParentMapping
  final List<Map<String, dynamic>> studentParentMappings = [
    // Aarav Sharma (Mother and Father)
    {
      'id': 'spm-101',
      'student_id': 'std-prof-501',
      'parent_id': 'par-prof-601',
      'relationship_type': 'FATHER',
      'is_primary_contact': true,
      'is_fee_payer': true
    },
    {
      'id': 'spm-102',
      'student_id': 'std-prof-501',
      'parent_id': 'par-prof-602',
      'relationship_type': 'MOTHER',
      'is_primary_contact': false,
      'is_fee_payer': false
    },
    // Diya Patel
    {
      'id': 'spm-103',
      'student_id': 'std-prof-502',
      'parent_id': 'par-prof-603',
      'relationship_type': 'FATHER',
      'is_primary_contact': true,
      'is_fee_payer': true
    },
    // Rohan Gupta
    {
      'id': 'spm-104',
      'student_id': 'std-prof-503',
      'parent_id': 'par-prof-604',
      'relationship_type': 'FATHER',
      'is_primary_contact': true,
      'is_fee_payer': true
    },
    // Ananya Reddy
    {
      'id': 'spm-105',
      'student_id': 'std-prof-504',
      'parent_id': 'par-prof-605',
      'relationship_type': 'FATHER',
      'is_primary_contact': true,
      'is_fee_payer': true
    },
    // Kabir Mehta (Sharing parent 601 / Sharma family sibling)
    {
      'id': 'spm-106',
      'student_id': 'std-prof-505',
      'parent_id': 'par-prof-601',
      'relationship_type': 'LEGAL_GUARDIAN',
      'is_primary_contact': true,
      'is_fee_payer': true
    },
    // Siddharth Varma (Discontinued student)
    {
      'id': 'spm-107',
      'student_id': 'std-prof-506',
      'parent_id': 'par-prof-606',
      'relationship_type': 'FATHER',
      'is_primary_contact': true,
      'is_fee_payer': true
    }
  ];

  // ---------------------------------------------------------------------------
  // 4. MODULE 1: ACADEMIC SETUP & TIMETABLE MODELS
  // ---------------------------------------------------------------------------

  // 1. Subject
  final List<Map<String, dynamic>> subjects = [
    {
      'id': 'sbj-101',
      'subject_name': 'Mathematics',
      'subject_code': 'MATH-101',
      'department': 'Mathematics',
      'description': 'Advanced algebra, coordinate geometry, trigonometry, and calculus basics.',
      'is_practical': false,
      'is_active': true,
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    },
    {
      'id': 'sbj-102',
      'subject_name': 'Physics',
      'subject_code': 'PHY-201',
      'department': 'Sciences',
      'description': 'Mechanics, wave optics, electricity, and electromagnetic theory.',
      'is_practical': true,
      'is_active': true,
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    },
    {
      'id': 'sbj-103',
      'subject_name': 'Chemistry',
      'subject_code': 'CHEM-202',
      'department': 'Sciences',
      'description': 'Physical, organic, and inorganic chemistry principles with lab titrations.',
      'is_practical': true,
      'is_active': true,
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    },
    {
      'id': 'sbj-104',
      'subject_name': 'Computer Science',
      'subject_code': 'CS-301',
      'department': 'Computer Science',
      'description': 'Data structures, algorithms, Python programming, and relational SQL.',
      'is_practical': true,
      'is_active': true,
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    },
    {
      'id': 'sbj-105',
      'subject_name': 'English Core',
      'subject_code': 'ENG-001',
      'department': 'Languages',
      'description': 'Reading comprehension, creative writing, and classical literature analysis.',
      'is_practical': false,
      'is_active': true,
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    },
    {
      'id': 'sbj-106',
      'subject_name': 'Social Science',
      'subject_code': 'SOC-102',
      'department': 'Humanities',
      'description': 'Modern Indian history, democratic politics, and economic development.',
      'is_practical': false,
      'is_active': true,
      'created_at': '2024-01-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    }
  ];

  // 2. ClassSubjectAllocation
  final List<Map<String, dynamic>> classSubjectAllocations = [
    // Class 10A
    {
      'id': 'csa-10a-math',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-101',
      'teacher_id': 'tch-prof-301',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'csa-10a-phy',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-102',
      'teacher_id': 'tch-prof-302',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'csa-10a-chem',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-103',
      'teacher_id': 'tch-prof-303',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'csa-10a-cs',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-104',
      'teacher_id': 'tch-prof-304',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'csa-10a-eng',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-105',
      'teacher_id': 'tch-prof-305',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'csa-10a-soc',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-106',
      'teacher_id': 'tch-prof-306',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },

    // Class 10B
    {
      'id': 'csa-10b-math',
      'class_section_id': 'cls-sec-10b',
      'subject_id': 'sbj-101',
      'teacher_id': 'tch-prof-301',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'csa-10b-eng',
      'class_section_id': 'cls-sec-10b',
      'subject_id': 'sbj-105',
      'teacher_id': 'tch-prof-305',
      'academic_year': '2026-2027',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    }
  ];

  // 3. TimetableSlot
  final List<Map<String, dynamic>> timetableSlots = [
    // Class 10A - Monday
    {
      'id': 'tts-10a-mon-p1',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-101', // Math
      'teacher_id': 'tch-prof-301',
      'day_of_week': 'MONDAY',
      'period_number': 1,
      'start_time': '08:30:00',
      'end_time': '09:15:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'tts-10a-mon-p2',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-102', // Physics
      'teacher_id': 'tch-prof-302',
      'day_of_week': 'MONDAY',
      'period_number': 2,
      'start_time': '09:15:00',
      'end_time': '10:00:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'tts-10a-mon-p3',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-103', // Chemistry
      'teacher_id': 'tch-prof-303',
      'day_of_week': 'MONDAY',
      'period_number': 3,
      'start_time': '10:15:00',
      'end_time': '11:00:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'tts-10a-mon-p4',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-104', // CS
      'teacher_id': 'tch-prof-304',
      'day_of_week': 'MONDAY',
      'period_number': 4,
      'start_time': '11:00:00',
      'end_time': '11:45:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'tts-10a-mon-p5',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-105', // English
      'teacher_id': 'tch-prof-305',
      'day_of_week': 'MONDAY',
      'period_number': 5,
      'start_time': '12:30:00',
      'end_time': '13:15:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'tts-10a-mon-p6',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-106', // Social Science
      'teacher_id': 'tch-prof-306',
      'day_of_week': 'MONDAY',
      'period_number': 6,
      'start_time': '13:15:00',
      'end_time': '14:00:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },

    // Class 10A - Tuesday
    {
      'id': 'tts-10a-tue-p1',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-102', // Physics
      'teacher_id': 'tch-prof-302',
      'day_of_week': 'TUESDAY',
      'period_number': 1,
      'start_time': '08:30:00',
      'end_time': '09:15:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    },
    {
      'id': 'tts-10a-tue-p2',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-101', // Math
      'teacher_id': 'tch-prof-301',
      'day_of_week': 'TUESDAY',
      'period_number': 2,
      'start_time': '09:15:00',
      'end_time': '10:00:00',
      'is_active': true,
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-01T09:00:00.000Z'
    }
  ];

  // 4. TimetableSubstitution
  final List<Map<String, dynamic>> timetableSubstitutions = [
    {
      'id': 'subst-2026-01',
      'timetable_slot_id': 'tts-10a-mon-p2',
      'substitution_date': '2026-10-19',
      'original_teacher_id': 'tch-prof-302', // Vikramaditya Sen (On leave)
      'substitute_teacher_id': 'tch-prof-304', // Amit Chatterjee
      'assigned_by_admin_id': 'usr-adm-001',
      'status': 'CONFIRMED',
      'reason': 'Medical leave coverage for senior physics session',
      'notes': 'Conduct lab revision on Wave Optics chapter',
      'created_at': '2026-10-16T14:00:00.000Z',
      'updated_at': '2026-10-16T14:30:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 5. MODULE 2: DAILY ATTENDANCE & ALERTS MODELS
  // ---------------------------------------------------------------------------

  // 1. DailyAttendanceSession
  final List<Map<String, dynamic>> dailyAttendanceSessions = [
    {
      'id': 'att-sess-2026-10-16-10a',
      'class_section_id': 'cls-sec-10a',
      'attendance_date': '2026-10-16',
      'taken_by_teacher_id': 'tch-prof-301',
      'submitted_at': '2026-10-16T08:45:00.000Z',
      'is_locked': true,
      'status': 'SUBMITTED',
      'total_students': 3,
      'created_at': '2026-10-16T08:35:00.000Z',
      'updated_at': '2026-10-16T08:45:00.000Z'
    },
    {
      'id': 'att-sess-2026-10-17-10a',
      'class_section_id': 'cls-sec-10a',
      'attendance_date': '2026-10-17',
      'taken_by_teacher_id': 'tch-prof-301',
      'submitted_at': '2026-10-17T08:40:00.000Z',
      'is_locked': true,
      'status': 'SUBMITTED',
      'total_students': 3,
      'created_at': '2026-10-17T08:30:00.000Z',
      'updated_at': '2026-10-17T08:40:00.000Z'
    }
  ];

  // 2. StudentAttendanceEntry
  final List<Map<String, dynamic>> studentAttendanceEntries = [
    // 2026-10-16 entries for Class 10A
    {
      'id': 'att-entry-101',
      'session_id': 'att-sess-2026-10-16-10a',
      'student_id': 'std-prof-501', // Aarav Sharma
      'status': 'PRESENT',
      'remarks': 'On time',
      'marked_by_teacher_id': 'tch-prof-301',
      'created_at': '2026-10-16T08:40:00.000Z',
      'updated_at': '2026-10-16T08:45:00.000Z'
    },
    {
      'id': 'att-entry-102',
      'session_id': 'att-sess-2026-10-16-10a',
      'student_id': 'std-prof-502', // Diya Patel
      'status': 'ABSENT',
      'remarks': 'Fever reported by parent via SMS',
      'marked_by_teacher_id': 'tch-prof-301',
      'created_at': '2026-10-16T08:41:00.000Z',
      'updated_at': '2026-10-16T08:45:00.000Z'
    },
    {
      'id': 'att-entry-103',
      'session_id': 'att-sess-2026-10-16-10a',
      'student_id': 'std-prof-506', // Siddharth Varma (Before exit)
      'status': 'EXCUSED',
      'remarks': 'TC documentation clearance in progress',
      'marked_by_teacher_id': 'tch-prof-301',
      'created_at': '2026-10-16T08:42:00.000Z',
      'updated_at': '2026-10-16T08:45:00.000Z'
    },

    // 2026-10-17 entries for Class 10A
    {
      'id': 'att-entry-104',
      'session_id': 'att-sess-2026-10-17-10a',
      'student_id': 'std-prof-501',
      'status': 'PRESENT',
      'remarks': null,
      'marked_by_teacher_id': 'tch-prof-301',
      'created_at': '2026-10-17T08:35:00.000Z',
      'updated_at': '2026-10-17T08:40:00.000Z'
    },
    {
      'id': 'att-entry-105',
      'session_id': 'att-sess-2026-10-17-10a',
      'student_id': 'std-prof-502',
      'status': 'PRESENT',
      'remarks': 'Resumed after fever recovery',
      'marked_by_teacher_id': 'tch-prof-301',
      'created_at': '2026-10-17T08:36:00.000Z',
      'updated_at': '2026-10-17T08:40:00.000Z'
    }
  ];

  // 3. AttendanceAlertLog
  final List<Map<String, dynamic>> attendanceAlertLogs = [
    {
      'id': 'alert-log-001',
      'student_attendance_entry_id': 'att-entry-102',
      'parent_id': 'par-prof-603', // Bhavin Patel
      'channel': 'SMS',
      'recipient_address': '+91 98765 77003',
      'delivery_status': 'SENT',
      'message': 'Dear Parent, your ward Diya Patel has been marked ABSENT on 16-Oct-2026 for Class 10A. Kindly verify with EduPulse School.',
      'dispatched_at': '2026-10-16T08:46:12.000Z',
      'created_at': '2026-10-16T08:45:00.000Z',
      'updated_at': '2026-10-16T08:46:12.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 6. MODULE 3: COURSEWORK & ASSIGNMENT MODELS
  // ---------------------------------------------------------------------------

  // 1. Assignment
  final List<Map<String, dynamic>> assignments = [
    {
      'id': 'asg-2026-math-01',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-101',
      'teacher_id': 'tch-prof-301',
      'title': 'Quadratic Equations & Analytical Applications',
      'description': 'Solve problems 1 to 25 from Section 4.2. Show complete derivation and graph plotting.',
      'question_file_url': 'https://cdn.edupulse.edu.in/assignments/math_ch4_problems.pdf',
      'due_date': '2026-10-24T23:59:59.000Z',
      'priority': 'HIGH',
      'max_score': 100.00,
      'status': 'PUBLISHED',
      'published_at': '2026-10-14T10:00:00.000Z',
      'academic_year': '2026-2027',
      'updated_by': 'usr-tch-301',
      'created_at': '2026-10-14T09:30:00.000Z',
      'updated_at': '2026-10-14T10:00:00.000Z'
    },
    {
      'id': 'asg-2026-phy-01',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-102',
      'teacher_id': 'tch-prof-302',
      'title': 'Optics Ray Diagrams & Refraction Through Lenses',
      'description': 'Construct ray diagrams for convex and concave lenses with different object distances.',
      'question_file_url': 'https://cdn.edupulse.edu.in/assignments/physics_optics_lab_worksheet.pdf',
      'due_date': '2026-10-22T23:59:59.000Z',
      'priority': 'MEDIUM',
      'max_score': 50.00,
      'status': 'PUBLISHED',
      'published_at': '2026-10-12T11:00:00.000Z',
      'academic_year': '2026-2027',
      'updated_by': 'usr-tch-302',
      'created_at': '2026-10-12T10:30:00.000Z',
      'updated_at': '2026-10-12T11:00:00.000Z'
    }
  ];

  // 2. AssignmentSubmission
  final List<Map<String, dynamic>> assignmentSubmissions = [
    {
      'id': 'subm-101',
      'assignment_id': 'asg-2026-math-01',
      'student_id': 'std-prof-501', // Aarav Sharma
      'submission_file_url': 'https://cdn.edupulse.edu.in/submissions/aarav_math_assignment_1.pdf',
      'student_notes': 'Completed all questions including quadratic curve sketching.',
      'submitted_at': '2026-10-18T16:45:00.000Z',
      'is_late': false,
      'score_awarded': 96.50,
      'teacher_feedback': 'Excellent mathematical reasoning and clear graphs.',
      'graded_at': '2026-10-19T11:20:00.000Z',
      'graded_by_teacher_id': 'tch-prof-301',
      'created_at': '2026-10-18T16:45:00.000Z',
      'updated_at': '2026-10-19T11:20:00.000Z'
    },
    {
      'id': 'subm-102',
      'assignment_id': 'asg-2026-phy-01',
      'student_id': 'std-prof-502', // Diya Patel
      'submission_file_url': 'https://cdn.edupulse.edu.in/submissions/diya_optics_diagrams.pdf',
      'student_notes': 'Attached high resolution scans of ray diagrams.',
      'submitted_at': '2026-10-19T14:10:00.000Z',
      'is_late': false,
      'score_awarded': 48.00,
      'teacher_feedback': 'Precise angles and focal measurement indicators.',
      'graded_at': '2026-10-20T09:15:00.000Z',
      'graded_by_teacher_id': 'tch-prof-302',
      'created_at': '2026-10-19T14:10:00.000Z',
      'updated_at': '2026-10-20T09:15:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 7. MODULE 4: EXAMINATION, GRADING & REPORT CARD MODELS
  // ---------------------------------------------------------------------------

  // 1. ExamSchedule
  final List<Map<String, dynamic>> examSchedules = [
    {
      'id': 'exam-sch-midterm-2026',
      'title': 'Mid-Term Comprehensive Examination 2026',
      'academic_year': '2026-2027',
      'status': 'COMPLETED',
      'description': 'Mandatory term 1 evaluation across all subjects and grades.',
      'start_date': '2026-09-15',
      'end_date': '2026-09-28',
      'created_at': '2026-08-01T09:00:00.000Z',
      'updated_at': '2026-10-01T09:00:00.000Z'
    },
    {
      'id': 'exam-sch-finals-2027',
      'title': 'Annual Board Pre-Finals 2027',
      'academic_year': '2026-2027',
      'status': 'PLANNED',
      'description': 'Final preparatory testing cycle conforming to national board pattern.',
      'start_date': '2027-01-10',
      'end_date': '2027-01-25',
      'created_at': '2026-10-10T09:00:00.000Z',
      'updated_at': '2026-10-10T09:00:00.000Z'
    }
  ];

  // 2. ExamPaper
  final List<Map<String, dynamic>> examPapers = [
    {
      'id': 'ex-paper-10a-math',
      'exam_schedule_id': 'exam-sch-midterm-2026',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-101',
      'exam_date': '2026-09-16',
      'start_time': '09:00:00',
      'end_time': '12:00:00',
      'max_marks': 100.00,
      'passing_marks': 35.00,
      'invigilator_id': 'tch-prof-302',
      'status': 'COMPLETED',
      'created_at': '2026-08-15T09:00:00.000Z',
      'updated_at': '2026-09-16T13:00:00.000Z'
    },
    {
      'id': 'ex-paper-10a-phy',
      'exam_schedule_id': 'exam-sch-midterm-2026',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-102',
      'exam_date': '2026-09-18',
      'start_time': '09:00:00',
      'end_time': '12:00:00',
      'max_marks': 100.00,
      'passing_marks': 35.00,
      'invigilator_id': 'tch-prof-301',
      'status': 'COMPLETED',
      'created_at': '2026-08-15T09:00:00.000Z',
      'updated_at': '2026-09-18T13:00:00.000Z'
    },
    {
      'id': 'ex-paper-10a-chem',
      'exam_schedule_id': 'exam-sch-midterm-2026',
      'class_section_id': 'cls-sec-10a',
      'subject_id': 'sbj-103',
      'exam_date': '2026-09-21',
      'start_time': '09:00:00',
      'end_time': '12:00:00',
      'max_marks': 100.00,
      'passing_marks': 35.00,
      'invigilator_id': 'tch-prof-304',
      'status': 'COMPLETED',
      'created_at': '2026-08-15T09:00:00.000Z',
      'updated_at': '2026-09-21T13:00:00.000Z'
    }
  ];

  // 3. StudentExamMark
  final List<Map<String, dynamic>> studentExamMarks = [
    // Aarav Sharma
    {
      'id': 'sem-101',
      'exam_paper_id': 'ex-paper-10a-math',
      'student_id': 'std-prof-501',
      'marks_obtained': 95.00,
      'is_absent': false,
      'entered_by_teacher_id': 'tch-prof-301',
      'remarks': 'Outstanding algebra & trigonometry performance',
      'created_at': '2026-09-20T10:00:00.000Z',
      'updated_at': '2026-09-20T10:00:00.000Z'
    },
    {
      'id': 'sem-102',
      'exam_paper_id': 'ex-paper-10a-phy',
      'student_id': 'std-prof-501',
      'marks_obtained': 91.50,
      'is_absent': false,
      'entered_by_teacher_id': 'tch-prof-302',
      'remarks': 'Thorough understanding of electrical circuits',
      'created_at': '2026-09-22T11:00:00.000Z',
      'updated_at': '2026-09-22T11:00:00.000Z'
    },
    {
      'id': 'sem-103',
      'exam_paper_id': 'ex-paper-10a-chem',
      'student_id': 'std-prof-501',
      'marks_obtained': 89.00,
      'is_absent': false,
      'entered_by_teacher_id': 'tch-prof-303',
      'remarks': 'Good chemical equation balancing',
      'created_at': '2026-09-24T14:00:00.000Z',
      'updated_at': '2026-09-24T14:00:00.000Z'
    },

    // Diya Patel
    {
      'id': 'sem-104',
      'exam_paper_id': 'ex-paper-10a-math',
      'student_id': 'std-prof-502',
      'marks_obtained': 98.00,
      'is_absent': false,
      'entered_by_teacher_id': 'tch-prof-301',
      'remarks': 'Top score in class; near perfection in geometry',
      'created_at': '2026-09-20T10:05:00.000Z',
      'updated_at': '2026-09-20T10:05:00.000Z'
    },
    {
      'id': 'sem-105',
      'exam_paper_id': 'ex-paper-10a-phy',
      'student_id': 'std-prof-502',
      'marks_obtained': 94.00,
      'is_absent': false,
      'entered_by_teacher_id': 'tch-prof-302',
      'remarks': 'Exemplary numerical solving ability',
      'created_at': '2026-09-22T11:05:00.000Z',
      'updated_at': '2026-09-22T11:05:00.000Z'
    },
    {
      'id': 'sem-106',
      'exam_paper_id': 'ex-paper-10a-chem',
      'student_id': 'std-prof-502',
      'marks_obtained': 93.00,
      'is_absent': false,
      'entered_by_teacher_id': 'tch-prof-303',
      'remarks': 'Clear conceptual grasp on periodic trends',
      'created_at': '2026-09-24T14:05:00.000Z',
      'updated_at': '2026-09-24T14:05:00.000Z'
    }
  ];

  // 4. ReportCard
  final List<Map<String, dynamic>> reportCards = [
    {
      'id': 'rep-card-101',
      'student_id': 'std-prof-501', // Aarav Sharma
      'exam_schedule_id': 'exam-sch-midterm-2026',
      'total_marks_obtained': 275.50,
      'total_max_marks': 300.00,
      'percentage': 91.83,
      'grade': 'A+',
      'gpa': 3.90,
      'class_rank': 2,
      'class_incharge_remarks': 'Aarav is an intellectually sharp and diligent student. Maintains top-tier performance consistently.',
      'is_approved_by_principal': true,
      'approved_at': '2026-10-02T16:00:00.000Z',
      'is_published': true,
      'published_at': '2026-10-03T09:00:00.000Z',
      'created_at': '2026-10-01T10:00:00.000Z',
      'updated_at': '2026-10-03T09:00:00.000Z'
    },
    {
      'id': 'rep-card-102',
      'student_id': 'std-prof-502', // Diya Patel
      'exam_schedule_id': 'exam-sch-midterm-2026',
      'total_marks_obtained': 285.00,
      'total_max_marks': 300.00,
      'percentage': 95.00,
      'grade': 'A+',
      'gpa': 4.00,
      'class_rank': 1,
      'class_incharge_remarks': 'Secured 1st rank in class! Demonstrates exemplary academic discipline and peer leadership.',
      'is_approved_by_principal': true,
      'approved_at': '2026-10-02T16:05:00.000Z',
      'is_published': true,
      'published_at': '2026-10-03T09:00:00.000Z',
      'created_at': '2026-10-01T10:00:00.000Z',
      'updated_at': '2026-10-03T09:00:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 8. MODULE 5: FINANCE & ACCOUNTS MODELS
  // ---------------------------------------------------------------------------

  // 1. FeeStructure
  final List<Map<String, dynamic>> feeStructures = [
    {
      'id': 'fee-str-10-term1',
      'class_name': 'Class 10',
      'term_name': 'Term 1',
      'academic_year': '2026-2027',
      'tuition_fee': 28000.00,
      'other_fee': 3500.00,
      'total_fee': 42500.00,
      'is_active': true,
      'lab_computer_fee': 6000.00,
      'development_fee': 5000.00,
      'due_date': '2026-11-15',
      'created_at': '2026-05-01T09:00:00.000Z',
      'updated_at': '2026-05-01T09:00:00.000Z'
    },
    {
      'id': 'fee-str-11-term1',
      'class_name': 'Class 11',
      'term_name': 'Term 1',
      'academic_year': '2026-2027',
      'tuition_fee': 32000.00,
      'other_fee': 4000.00,
      'total_fee': 49000.00,
      'is_active': true,
      'lab_computer_fee': 8000.00,
      'development_fee': 5000.00,
      'due_date': '2026-11-15',
      'created_at': '2026-05-01T09:00:00.000Z',
      'updated_at': '2026-05-01T09:00:00.000Z'
    },
    {
      'id': 'fee-str-12-term1',
      'class_name': 'Class 12',
      'term_name': 'Term 1',
      'academic_year': '2026-2027',
      'tuition_fee': 35000.00,
      'other_fee': 4500.00,
      'total_fee': 53500.00,
      'is_active': true,
      'lab_computer_fee': 8000.00,
      'development_fee': 6000.00,
      'due_date': '2026-11-15',
      'created_at': '2026-05-01T09:00:00.000Z',
      'updated_at': '2026-05-01T09:00:00.000Z'
    }
  ];

  // 2. StudentFeeInvoice
  final List<Map<String, dynamic>> studentFeeInvoices = [
    {
      'id': 'inv-2026-0042',
      'invoice_number': 'INV-2026-0042',
      'student_id': 'std-prof-501', // Aarav Sharma
      'fee_structure_id': 'fee-str-10-term1',
      'base_amount': 42500.00,
      'concession_amount': 5000.00,
      'late_fine_amount': 0.00,
      'total_payable': 37500.00,
      'amount_paid': 37500.00,
      'payment_status': 'PAID',
      'due_date': '2026-11-15',
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-10T14:30:00.000Z'
    },
    {
      'id': 'inv-2026-0043',
      'invoice_number': 'INV-2026-0043',
      'student_id': 'std-prof-502', // Diya Patel
      'fee_structure_id': 'fee-str-10-term1',
      'base_amount': 42500.00,
      'concession_amount': 0.00,
      'late_fine_amount': 0.00,
      'total_payable': 42500.00,
      'amount_paid': 20000.00,
      'payment_status': 'PARTIALLY_PAID',
      'due_date': '2026-11-15',
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-06-15T11:00:00.000Z'
    },
    {
      'id': 'inv-2026-0044',
      'invoice_number': 'INV-2026-0044',
      'student_id': 'std-prof-503', // Rohan Gupta
      'fee_structure_id': 'fee-str-10-term1',
      'base_amount': 42500.00,
      'concession_amount': 0.00,
      'late_fine_amount': 500.00,
      'total_payable': 43000.00,
      'amount_paid': 0.00,
      'payment_status': 'OVERDUE',
      'due_date': '2026-09-30',
      'created_at': '2026-06-01T09:00:00.000Z',
      'updated_at': '2026-10-01T00:00:00.000Z'
    }
  ];

  // 3. FeePaymentTransaction
  final List<Map<String, dynamic>> feePaymentTransactions = [
    {
      'id': 'txn-2026-901',
      'invoice_id': 'inv-2026-0042',
      'transaction_reference': 'TXN-RAZOR-981248102',
      'gateway_name': 'Razorpay',
      'amount': 37500.00,
      'status': 'SUCCESS',
      'payment_method': 'UPI',
      'receipt_url': 'https://cdn.edupulse.edu.in/receipts/rec-2026-0042.pdf',
      'settled_at': '2026-06-10T14:30:15.000Z',
      'created_at': '2026-06-10T14:28:00.000Z',
      'updated_at': '2026-06-10T14:30:15.000Z'
    },
    {
      'id': 'txn-2026-902',
      'invoice_id': 'inv-2026-0043',
      'transaction_reference': 'TXN-CASH-DESK-0192',
      'gateway_name': 'Cash Desk',
      'amount': 20000.00,
      'status': 'SUCCESS',
      'payment_method': 'Cash Desk Counter',
      'receipt_url': 'https://cdn.edupulse.edu.in/receipts/rec-2026-0043.pdf',
      'settled_at': '2026-06-15T11:00:00.000Z',
      'created_at': '2026-06-15T10:55:00.000Z',
      'updated_at': '2026-06-15T11:00:00.000Z'
    },
    {
      'id': 'txn-2026-903',
      'invoice_id': 'inv-2026-0044',
      'transaction_reference': 'TXN-RAZOR-FAIL-7761',
      'gateway_name': 'Razorpay',
      'amount': 42500.00,
      'status': 'FAILED',
      'payment_method': 'NetBanking',
      'receipt_url': null,
      'settled_at': null,
      'created_at': '2026-10-05T18:20:00.000Z',
      'updated_at': '2026-10-05T18:22:00.000Z'
    }
  ];

  // 4. PaymentReconciliationTicket
  final List<Map<String, dynamic>> paymentReconciliationTickets = [
    {
      'id': 'prt-ticket-101',
      'transaction_id': 'txn-2026-903',
      'parent_id': 'par-prof-604', // Sanjay Gupta
      'issue_description': 'Rs. 42,500 was deducted from HDFC Bank account but portal showed Payment Failed status.',
      'resolution_type': 'MANUAL_RECONCILED',
      'resolution_notes': 'Bank confirmation UTR verified from Razorpay dashboard. Invoice adjusted and receipt issued.',
      'resolved_by_officer_id': 'usr-fin-201',
      'status': 'RESOLVED',
      'created_at': '2026-10-06T09:15:00.000Z',
      'updated_at': '2026-10-06T15:30:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 9. MODULE 6: STAFF LEAVE ADMINISTRATION MODEL
  // ---------------------------------------------------------------------------

  // 1. StaffLeaveApplication
  final List<Map<String, dynamic>> staffLeaveApplications = [
    {
      'id': 'sla-2026-001',
      'teacher_id': 'tch-prof-302', // Vikramaditya Sen
      'leave_type': 'MEDICAL',
      'start_date': '2026-10-19',
      'end_date': '2026-10-20',
      'reason': 'Scheduled dental surgery and recovery',
      'status': 'APPROVED',
      'reviewed_by_admin_id': 'usr-adm-001',
      'admin_remarks': 'Approved with substitute coverage assigned to Amit Chatterjee',
      'reviewed_at': '2026-10-16T14:30:00.000Z',
      'total_days': 2.0,
      'created_at': '2026-10-15T11:00:00.000Z',
      'updated_at': '2026-10-16T14:30:00.000Z'
    },
    {
      'id': 'sla-2026-002',
      'teacher_id': 'tch-prof-301', // Dr. Rajeshwari
      'leave_type': 'CASUAL',
      'start_date': '2026-11-04',
      'end_date': '2026-11-05',
      'reason': 'Attending national mathematics Olympiad committee meeting as keynote delegate',
      'status': 'APPROVED',
      'reviewed_by_admin_id': 'usr-adm-001',
      'admin_remarks': 'Approved on Duty Leave protocol; prestigious recognition for school.',
      'reviewed_at': '2026-10-17T09:00:00.000Z',
      'total_days': 2.0,
      'created_at': '2026-10-16T16:00:00.000Z',
      'updated_at': '2026-10-17T09:00:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 10. MODULE 7: DISCONTINUATION & TRANSFER CERTIFICATE (TC) MODELS
  // ---------------------------------------------------------------------------

  // 1. DiscontinuationRequest
  final List<Map<String, dynamic>> discontinuationRequests = [
    {
      'id': 'disc-req-2026-001',
      'student_id': 'std-prof-506', // Siddharth Varma
      'parent_id': 'par-prof-606', // Manish Varma
      'reason': 'Father transferred to corporate headquarters in Mumbai, Maharashtra.',
      'requested_exit_date': '2026-10-15',
      'reviewed_by_admin_id': 'usr-adm-001',
      'admin_remarks': 'All 4 departmental clearances verified. Formally cleared for TC issuance.',
      'overall_status': 'CLEARED',
      'created_at': '2026-10-01T10:00:00.000Z',
      'updated_at': '2026-10-14T11:30:00.000Z'
    }
  ];

  // 2. DepartmentalClearance
  final List<Map<String, dynamic>> departmentalClearances = [
    {
      'id': 'dept-clr-001',
      'discontinuation_request_id': 'disc-req-2026-001',
      'department': 'LIBRARY',
      'status': 'CLEARED',
      'verified_by_user_id': 'usr-sup-401', // Geetha Krishnan (Librarian)
      'remarks': 'All 4 borrowed library books returned in intact condition. No library fines.',
      'verified_at': '2026-10-05T14:15:00.000Z',
      'created_at': '2026-10-01T10:05:00.000Z',
      'updated_at': '2026-10-05T14:15:00.000Z'
    },
    {
      'id': 'dept-clr-002',
      'discontinuation_request_id': 'disc-req-2026-001',
      'department': 'ACCOUNTS_FINANCE',
      'status': 'CLEARED',
      'verified_by_user_id': 'usr-fin-201', // K. R. Ramanathan (Finance)
      'remarks': 'Term 1 dues completely settled. Caution deposit refund processed.',
      'verified_at': '2026-10-08T11:45:00.000Z',
      'created_at': '2026-10-01T10:05:00.000Z',
      'updated_at': '2026-10-08T11:45:00.000Z'
    },
    {
      'id': 'dept-clr-003',
      'discontinuation_request_id': 'disc-req-2026-001',
      'department': 'HOSTEL_TRANSPORT',
      'status': 'CLEARED',
      'verified_by_user_id': 'usr-sup-403', // Harpreet Singh (Transport Head)
      'remarks': 'Bus pass card surrendered. Bus route #08 clearance signed.',
      'verified_at': '2026-10-10T16:20:00.000Z',
      'created_at': '2026-10-01T10:05:00.000Z',
      'updated_at': '2026-10-10T16:20:00.000Z'
    },
    {
      'id': 'dept-clr-004',
      'discontinuation_request_id': 'disc-req-2026-001',
      'department': 'LABS_INVENTORY',
      'status': 'CLEARED',
      'verified_by_user_id': 'usr-sup-402', // Subhash Bose (Lab Tech)
      'remarks': 'Physics, Chemistry, and Computer Science lab lockers vacated; equipment checked.',
      'verified_at': '2026-10-12T15:00:00.000Z',
      'created_at': '2026-10-01T10:05:00.000Z',
      'updated_at': '2026-10-12T15:00:00.000Z'
    }
  ];

  // 3. TransferCertificate
  final List<Map<String, dynamic>> transferCertificates = [
    {
      'id': 'tc-cert-901',
      'discontinuation_request_id': 'disc-req-2026-001',
      'student_id': 'std-prof-506',
      'tc_number': 'TC-2026-0042',
      'issue_date': '2026-10-14',
      'conduct_remark': 'Exemplary',
      'signed_by_admin_id': 'usr-adm-001', // Dr. Ananya Deshmukh (Principal)
      'pdf_document_url': 'https://cdn.edupulse.edu.in/certificates/tc-2026-0042.pdf',
      'reason_for_leaving': 'Parent relocation to Mumbai, Maharashtra.',
      'created_at': '2026-10-14T11:30:00.000Z',
      'updated_at': '2026-10-14T11:30:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 11. MODULE 8: GOVERNANCE & BROADCAST COMMUNICATION MODEL
  // ---------------------------------------------------------------------------

  // 1. SchoolAnnouncement
  final List<Map<String, dynamic>> schoolAnnouncements = [
    {
      'id': 'anc-2026-001',
      'author_id': 'usr-adm-001',
      'title': 'Annual Inter-School Science & Innovation Expo 2026',
      'content': 'We are delighted to announce that EduPulse will host the CBSE Regional Science Expo on November 14-15, 2026. Student project registrations open next Monday.',
      'target_audience': 'ALL',
      'status': 'PUBLISHED',
      'published_at': '2026-10-15T09:00:00.000Z',
      'expires_at': '2026-11-20T23:59:59.000Z',
      'attachment_url': 'https://cdn.edupulse.edu.in/bulletins/science_expo_circular_2026.pdf',
      'updated_at': '2026-10-15T09:00:00.000Z'
    },
    {
      'id': 'anc-2026-002',
      'author_id': 'usr-adm-002',
      'title': 'Faculty Development Workshop on Experiential STEM Pedagogies',
      'content': 'Mandatory pedagogy enrichment session for all PGT and TGT teachers on Saturday, October 25, from 10:00 AM to 1:00 PM in the Multi-Purpose Auditorium.',
      'target_audience': 'TEACHERS_ONLY',
      'status': 'PUBLISHED',
      'published_at': '2026-10-16T10:30:00.000Z',
      'expires_at': '2026-10-26T23:59:59.000Z',
      'attachment_url': null,
      'updated_at': '2026-10-16T10:30:00.000Z'
    },
    {
      'id': 'anc-2026-003',
      'author_id': 'usr-fin-201',
      'title': 'Term 2 Fee Schedule & Online Payment Window Announcement',
      'content': 'Dear Parents, Term 2 academic fees are now generated. Please use the UPI / NetBanking portal before November 15, 2026 to avoid late concession surcharges.',
      'target_audience': 'PARENTS_ONLY',
      'status': 'PUBLISHED',
      'published_at': '2026-10-17T08:00:00.000Z',
      'expires_at': '2026-11-16T23:59:59.000Z',
      'attachment_url': 'https://cdn.edupulse.edu.in/bulletins/term2_fee_circular.pdf',
      'updated_at': '2026-10-17T08:00:00.000Z'
    }
  ];

  // ---------------------------------------------------------------------------
  // 12. REFERENTIAL INTEGRITY VALIDATION
  // ---------------------------------------------------------------------------
  print('Validating cross-entity referential integrity...');
  final Set<String> userIds = users.map((u) => u['id'] as String).toSet();
  final Set<String> studentIds = studentProfiles.map((s) => s['id'] as String).toSet();
  final Set<String> teacherIds = teacherProfiles.map((t) => t['id'] as String).toSet();
  final Set<String> parentIds = parentProfiles.map((p) => p['id'] as String).toSet();
  final Set<String> classSectionIds = classSections.map((c) => c['id'] as String).toSet();
  final Set<String> subjectIds = subjects.map((s) => s['id'] as String).toSet();
  final Set<String> feeStructureIds = feeStructures.map((f) => f['id'] as String).toSet();
  final Set<String> invoiceIds = studentFeeInvoices.map((i) => i['id'] as String).toSet();
  final Set<String> examScheduleIds = examSchedules.map((e) => e['id'] as String).toSet();
  final Set<String> examPaperIds = examPapers.map((e) => e['id'] as String).toSet();
  final Set<String> assignmentIds = assignments.map((a) => a['id'] as String).toSet();
  final Set<String> discRequestIds = discontinuationRequests.map((d) => d['id'] as String).toSet();

  void checkFK(String context, String? id, Set<String> validSet) {
    if (id != null && !validSet.contains(id)) {
      throw StateError('Integrity error in $context: Referenced ID "$id" does not exist in target set!');
    }
  }

  for (final s in studentProfiles) {
    checkFK('StudentProfile.user_id', s['user_id'], userIds);
    checkFK('StudentProfile.current_class_id', s['current_class_id'], classSectionIds);
  }
  for (final t in teacherProfiles) {
    checkFK('TeacherProfile.user_id', t['user_id'], userIds);
  }
  for (final a in adminProfiles) {
    checkFK('AdminProfile.user_id', a['user_id'], userIds);
  }
  for (final o in admissionsOfficerProfiles) {
    checkFK('AdmissionsOfficerProfile.user_id', o['user_id'], userIds);
    checkFK('AdmissionsOfficerProfile.reporting_admin_id', o['reporting_admin_id'], userIds);
  }
  for (final f in financeOfficerProfiles) {
    checkFK('FinanceOfficerProfile.user_id', f['user_id'], userIds);
  }
  for (final sup in supportStaffProfiles) {
    checkFK('SupportStaffProfile.user_id', sup['user_id'], userIds);
  }
  for (final p in parentProfiles) {
    checkFK('ParentProfile.user_id', p['user_id'], userIds);
  }
  for (final spm in studentParentMappings) {
    checkFK('StudentParentMapping.student_id', spm['student_id'], studentIds);
    checkFK('StudentParentMapping.parent_id', spm['parent_id'], parentIds);
  }
  for (final cs in classSections) {
    checkFK('ClassSection.class_incharge_id', cs['class_incharge_id'], teacherIds);
  }
  for (final csa in classSubjectAllocations) {
    checkFK('ClassSubjectAllocation.class_section_id', csa['class_section_id'], classSectionIds);
    checkFK('ClassSubjectAllocation.subject_id', csa['subject_id'], subjectIds);
    checkFK('ClassSubjectAllocation.teacher_id', csa['teacher_id'], teacherIds);
  }
  for (final tts in timetableSlots) {
    checkFK('TimetableSlot.class_section_id', tts['class_section_id'], classSectionIds);
    checkFK('TimetableSlot.subject_id', tts['subject_id'], subjectIds);
    checkFK('TimetableSlot.teacher_id', tts['teacher_id'], teacherIds);
  }
  for (final sub in timetableSubstitutions) {
    checkFK('TimetableSubstitution.original_teacher_id', sub['original_teacher_id'], teacherIds);
    checkFK('TimetableSubstitution.substitute_teacher_id', sub['substitute_teacher_id'], teacherIds);
    checkFK('TimetableSubstitution.assigned_by_admin_id', sub['assigned_by_admin_id'], userIds);
  }
  for (final s in dailyAttendanceSessions) {
    checkFK('DailyAttendanceSession.class_section_id', s['class_section_id'], classSectionIds);
    checkFK('DailyAttendanceSession.taken_by_teacher_id', s['taken_by_teacher_id'], teacherIds);
  }
  for (final e in studentAttendanceEntries) {
    checkFK('StudentAttendanceEntry.student_id', e['student_id'], studentIds);
    checkFK('StudentAttendanceEntry.marked_by_teacher_id', e['marked_by_teacher_id'], teacherIds);
  }
  for (final asg in assignments) {
    checkFK('Assignment.class_section_id', asg['class_section_id'], classSectionIds);
    checkFK('Assignment.subject_id', asg['subject_id'], subjectIds);
    checkFK('Assignment.teacher_id', asg['teacher_id'], teacherIds);
  }
  for (final subm in assignmentSubmissions) {
    checkFK('AssignmentSubmission.assignment_id', subm['assignment_id'], assignmentIds);
    checkFK('AssignmentSubmission.student_id', subm['student_id'], studentIds);
    checkFK('AssignmentSubmission.graded_by_teacher_id', subm['graded_by_teacher_id'], teacherIds);
  }
  for (final ep in examPapers) {
    checkFK('ExamPaper.exam_schedule_id', ep['exam_schedule_id'], examScheduleIds);
    checkFK('ExamPaper.class_section_id', ep['class_section_id'], classSectionIds);
    checkFK('ExamPaper.subject_id', ep['subject_id'], subjectIds);
    checkFK('ExamPaper.invigilator_id', ep['invigilator_id'], teacherIds);
  }
  for (final sem in studentExamMarks) {
    checkFK('StudentExamMark.exam_paper_id', sem['exam_paper_id'], examPaperIds);
    checkFK('StudentExamMark.student_id', sem['student_id'], studentIds);
    checkFK('StudentExamMark.entered_by_teacher_id', sem['entered_by_teacher_id'], teacherIds);
  }
  for (final rc in reportCards) {
    checkFK('ReportCard.student_id', rc['student_id'], studentIds);
    checkFK('ReportCard.exam_schedule_id', rc['exam_schedule_id'], examScheduleIds);
  }
  for (final inv in studentFeeInvoices) {
    checkFK('StudentFeeInvoice.student_id', inv['student_id'], studentIds);
    checkFK('StudentFeeInvoice.fee_structure_id', inv['fee_structure_id'], feeStructureIds);
  }
  for (final txn in feePaymentTransactions) {
    checkFK('FeePaymentTransaction.invoice_id', txn['invoice_id'], invoiceIds);
  }
  for (final prt in paymentReconciliationTickets) {
    checkFK('PaymentReconciliationTicket.parent_id', prt['parent_id'], parentIds);
    checkFK('PaymentReconciliationTicket.resolved_by_officer_id', prt['resolved_by_officer_id'], userIds);
  }
  for (final sla in staffLeaveApplications) {
    checkFK('StaffLeaveApplication.teacher_id', sla['teacher_id'], teacherIds);
    checkFK('StaffLeaveApplication.reviewed_by_admin_id', sla['reviewed_by_admin_id'], userIds);
  }
  for (final d in discontinuationRequests) {
    checkFK('DiscontinuationRequest.student_id', d['student_id'], studentIds);
    checkFK('DiscontinuationRequest.parent_id', d['parent_id'], parentIds);
    checkFK('DiscontinuationRequest.reviewed_by_admin_id', d['reviewed_by_admin_id'], userIds);
  }
  for (final clr in departmentalClearances) {
    checkFK('DepartmentalClearance.discontinuation_request_id', clr['discontinuation_request_id'], discRequestIds);
    checkFK('DepartmentalClearance.verified_by_user_id', clr['verified_by_user_id'], userIds);
  }
  for (final tc in transferCertificates) {
    checkFK('TransferCertificate.discontinuation_request_id', tc['discontinuation_request_id'], discRequestIds);
    checkFK('TransferCertificate.student_id', tc['student_id'], studentIds);
    checkFK('TransferCertificate.signed_by_admin_id', tc['signed_by_admin_id'], userIds);
  }
  for (final anc in schoolAnnouncements) {
    checkFK('SchoolAnnouncement.author_id', anc['author_id'], userIds);
  }

  print('✓ All 27 entity relationships passed 100% referential integrity validation!');

  // ---------------------------------------------------------------------------
  // 13. MASTER BUNDLED DATABASE
  // ---------------------------------------------------------------------------
  final Map<String, dynamic> globalDatabase = {
    'version': '1.0.0',
    'institution': {
      'name': 'EduPulse Public School & Senior College',
      'affiliation_code': 'CBSE-AFF-2026-9021',
      'address': 'Campus 1, IT Corridor, Bellandur, Bengaluru, Karnataka 560103',
      'academic_year': '2026-2027',
      'contact_phone': '+91 80 4912 3000',
      'contact_email': 'info@edupulse.edu.in'
    },
    'users': users,
    'student_profiles': studentProfiles,
    'parent_profiles': parentProfiles,
    'teacher_profiles': teacherProfiles,
    'admin_profiles': adminProfiles,
    'admissions_officer_profiles': admissionsOfficerProfiles,
    'finance_officer_profiles': financeOfficerProfiles,
    'support_staff_profiles': supportStaffProfiles,
    'student_parent_mappings': studentParentMappings,
    'class_sections': classSections,
    'subjects': subjects,
    'class_subject_allocations': classSubjectAllocations,
    'timetable_slots': timetableSlots,
    'timetable_substitutions': timetableSubstitutions,
    'daily_attendance_sessions': dailyAttendanceSessions,
    'student_attendance_entries': studentAttendanceEntries,
    'attendance_alert_logs': attendanceAlertLogs,
    'assignments': assignments,
    'assignment_submissions': assignmentSubmissions,
    'exam_schedules': examSchedules,
    'exam_papers': examPapers,
    'student_exam_marks': studentExamMarks,
    'report_cards': reportCards,
    'fee_structures': feeStructures,
    'student_fee_invoices': studentFeeInvoices,
    'fee_payment_transactions': feePaymentTransactions,
    'payment_reconciliation_tickets': paymentReconciliationTickets,
    'staff_leave_applications': staffLeaveApplications,
    'discontinuation_requests': discontinuationRequests,
    'departmental_clearances': departmentalClearances,
    'transfer_certificates': transferCertificates,
    'school_announcements': schoolAnnouncements
  };

  const encoder = JsonEncoder.withIndent('  ');

  // Helper to ensure directory exists and write formatted JSON
  void writeJsonFile(String relativePath, Object data) {
    final file = File(relativePath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(encoder.convert(data));
    print('Wrote: $relativePath (${file.lengthSync()} bytes)');
  }

  // 1. Write Master Bundled Database
  writeJsonFile('assets/data/global_school_database.json', globalDatabase);

  // 2. Write Modular Files
  // A. Auth
  writeJsonFile('assets/data/auth/users.json', users);

  // B. Staff Global (All 5 profiles + staff leave)
  writeJsonFile('assets/data/staff/staff_global.json', {
    'admin_profiles': adminProfiles,
    'teacher_profiles': teacherProfiles,
    'admissions_officer_profiles': admissionsOfficerProfiles,
    'finance_officer_profiles': financeOfficerProfiles,
    'support_staff_profiles': supportStaffProfiles,
    'staff_leave_applications': staffLeaveApplications
  });

  // C. Students & Parents
  writeJsonFile('assets/data/students/students_and_parents.json', {
    'student_profiles': studentProfiles,
    'parent_profiles': parentProfiles,
    'student_parent_mappings': studentParentMappings
  });

  // D. Academics
  writeJsonFile('assets/data/academics/academic_setup.json', {
    'class_sections': classSections,
    'subjects': subjects,
    'class_subject_allocations': classSubjectAllocations,
    'timetable_slots': timetableSlots,
    'timetable_substitutions': timetableSubstitutions
  });

  // E. Attendance
  writeJsonFile('assets/data/attendance/attendance.json', {
    'daily_attendance_sessions': dailyAttendanceSessions,
    'student_attendance_entries': studentAttendanceEntries,
    'attendance_alert_logs': attendanceAlertLogs
  });

  // F. Coursework
  writeJsonFile('assets/data/coursework/coursework.json', {
    'assignments': assignments,
    'assignment_submissions': assignmentSubmissions
  });

  // G. Examinations
  writeJsonFile('assets/data/examinations/examinations.json', {
    'exam_schedules': examSchedules,
    'exam_papers': examPapers,
    'student_exam_marks': studentExamMarks,
    'report_cards': reportCards
  });

  // H. Finance
  writeJsonFile('assets/data/finance/finance.json', {
    'fee_structures': feeStructures,
    'student_fee_invoices': studentFeeInvoices,
    'fee_payment_transactions': feePaymentTransactions,
    'payment_reconciliation_tickets': paymentReconciliationTickets
  });

  // I. Transfers & Clearances
  writeJsonFile('assets/data/transfers/transfers.json', {
    'discontinuation_requests': discontinuationRequests,
    'departmental_clearances': departmentalClearances,
    'transfer_certificates': transferCertificates
  });

  // J. Announcements
  writeJsonFile('assets/data/announcements/announcements.json', schoolAnnouncements);

  print('=== Generation Complete! 11 JSON files created successfully ===');
}
