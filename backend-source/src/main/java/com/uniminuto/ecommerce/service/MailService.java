package com.uniminuto.ecommerce.service;

import com.uniminuto.ecommerce.entity.User;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

/**
 * Envía correos por SMTP. Si no hay SMTP configurado (spring.mail.host vacío) no falla:
 * escribe el enlace en la consola para poder probar el flujo en desarrollo.
 */
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);

    private final ObjectProvider<JavaMailSender> mailSender;
    private final String from;
    private final String host;

    public MailService(ObjectProvider<JavaMailSender> mailSender,
                       @Value("${app.mail.from}") String from,
                       @Value("${spring.mail.host:}") String host) {
        this.mailSender = mailSender;
        this.from = from;
        this.host = host;
    }

    public void sendPasswordReset(User user, String link, long expirationMinutes) {
        JavaMailSender sender = mailSender.getIfAvailable();
        if (sender == null || host == null || host.isBlank()) {
            log.warn("SMTP no configurado. Enlace de recuperación para {}: {}", user.getEmail(), link);
            return;
        }
        String html = """
                <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto">
                  <h2>Recupera tu contraseña</h2>
                  <p>Hola %s,</p>
                  <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta.</p>
                  <p><a href="%s" style="display:inline-block;padding:12px 20px;background:#4f46e5;color:#fff;
                        text-decoration:none;border-radius:8px">Restablecer contraseña</a></p>
                  <p>El enlace vence en %d minutos. Si no fuiste tú, ignora este correo.</p>
                </div>
                """.formatted(user.getFirstName(), link, expirationMinutes);
        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            helper.setFrom(from);
            helper.setTo(user.getEmail());
            helper.setSubject("Recuperación de contraseña");
            helper.setText(html, true);
            sender.send(message);
            log.info("Correo de recuperación enviado a {}", user.getEmail());
        } catch (MessagingException | MailException e) {
            log.error("No se pudo enviar el correo a {}. Enlace: {}", user.getEmail(), link, e);
        }
    }
}
