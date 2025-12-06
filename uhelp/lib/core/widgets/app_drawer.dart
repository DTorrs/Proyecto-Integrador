import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../models/user_model.dart';

class AppDrawer extends StatelessWidget {
  final User? user;
  final VoidCallback onLogout;

  const AppDrawer({
    Key? key,
    required this.user,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utilizamos este método para crear un drawer con fondo blanco
    return Theme(
      // Aseguramos que el drawer tenga el color adecuado en todos los módulos
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: Drawer(
        elevation: 16.0, // Aumentamos la elevación para una sombra más definida
        child: ListView(
          // No usamos padding: EdgeInsets.zero para evitar el overflow
          children: [
            _buildHeader(context),
            _buildMenuItem(
              context,
              title: 'Problemas',
              icon: Icons.warning_amber_rounded,
              route: AppRoutes.problemList,
            ),
            _buildMenuItem(
              context,
              title: 'Objetos Perdidos',
              icon: Icons.search,
              route: AppRoutes.lostItemList,
            ),
            _buildMenuItem(
              context,
              title: 'Mapa',
              icon: Icons.map,
              route: AppRoutes.map,
            ),
            _buildMenuItem(
              context,
              title: 'Anuncios',
              icon: Icons.campaign,
              route: AppRoutes.announcements,
            ),
            _buildMenuItem(
              context,
              title: 'Notificaciones',
              icon: Icons.notifications,
              route: AppRoutes.notifications,
        
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppTheme.errorColor),
              title: Text('Logout'),
              onTap: onLogout,
            ),
            // Añadimos un espacio al final para evitar que el último elemento
            // quede cortado o demasiado cerca del borde
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      // Reducimos el padding inferior para evitar problemas de espacio
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Usa solo el espacio necesario
        children: [
          Text(
            'UHelp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20, // Reducido para ahorrar espacio
                  backgroundColor: Colors.white,
                  child: user?.profilePicture != null
                      ? Image.network(user!.profilePicture!)
                      : Text(
                          user!.fullName.isNotEmpty ? user!.fullName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!.fullName,
                        style: TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user!.role,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}