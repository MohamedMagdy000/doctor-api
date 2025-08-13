# -*- coding: utf-8 -*-
# controllers/public_api.py
from odoo import http
from odoo.http import request
import json
import logging

_logger = logging.getLogger(__name__)

# ===== Helpers =====
def _split_complete_name(complete_name):
    """
    يحوّل 'All / Doctor / قلب' -> (['All','Doctor','قلب'], parent='All', child='Doctor')
    لو مفيش غير جزء واحد -> child='' (فاضي)
    """
    if not complete_name:
        return [], '', ''
    segs = [s.strip() for s in complete_name.split('/') if s and s.strip()]
    parent = segs[0] if len(segs) >= 1 else ''
    child  = segs[1] if len(segs) >= 2 else ''
    return segs, parent, child

def _tags_of_partner(p):
    return [{'id': t.id, 'name': t.name} for t in p.category_id]

# ===== Controllers =====
class PublicProductController(http.Controller):

    @http.route('/odoo/public/products', type='http', auth='public', methods=['GET'], cors='*')
    def get_products(self, **kwargs):
        """
        يرجّع قائمة المنتجات مع حقول واضحة للأب/الابن:
        id, name, category, category_id, category_parent, category_path, parent, child, segments[], image
        """
        try:
            products = request.env['product.template'].sudo().search([])
            result = []
            for p in products:
                cat = p.categ_id
                cat_name = cat.name if cat else ''
                cat_id = cat.id if cat else False
                parent_name = cat.parent_id.name if (cat and cat.parent_id) else ''
                complete_name = cat.complete_name if cat else ''   # مثال: "All / Doctor / قلب"

                segs, parent, child = _split_complete_name(complete_name or cat_name)

                result.append({
                    'id': p.id,
                    'name': p.name or '',
                    # معلومات التصنيف الخام من أودو
                    'category': cat_name,
                    'category_id': cat_id,
                    'category_parent': parent_name or False,
                    'category_path': complete_name,
                    # مفصّلة للاستخدام المباشر في الواجهة
                    'parent': parent,
                    'child': child,
                    'segments': segs,
                    # صورة مناسبة
                    'image': f'/web/image/product.template/{p.id}/image_512',
                    # يمكن لاحقًا إضافة السعر والكمية إن رغبت:
                    'list_price': p.list_price or 0.0,
                    'qty_available': p.qty_available if hasattr(p, 'qty_available') else 0.0,
                })

            return request.make_response(
                json.dumps(result, ensure_ascii=False),
                headers=[('Content-Type', 'application/json; charset=utf-8')]
            )
        except Exception as e:
            _logger.exception('Error in /odoo/public/products: %s', e)
            return request.make_response(
                json.dumps({'error': 'internal_error', 'details': str(e)}),
                headers=[('Content-Type', 'application/json')],
                status=500
            )

class PublicContactController(http.Controller):

    @http.route('/odoo/public/contacts', type='http', auth='public', methods=['GET'], cors='*')
    def get_contacts(self, **kwargs):
        """
        يرجّع قائمة الكونتاكتس (res.partner) بالحقول:
        id, name, image, website, phone, mobile, email,
        title (Mr/Ms..), job_title (function), state, state_id,
        city, country, address, tags[], tag_ids[]

        بارامز اختيارية:
          - is_company=true/false
          - has_website=true/false
          - country=<country_name>
          - state=<state_name>
          - search=<substring in name/email/phone/website>
          - tag_id=<int> أو tag=<tag_name>
          - limit=<int> (افتراضي 80)
          - offset=<int> (افتراضي 0)
        """
        try:
            Partner = request.env['res.partner'].sudo()
            domain = []

            is_company = kwargs.get('is_company')
            if is_company is not None:
                domain.append(('is_company', '=', is_company.lower() == 'true'))

            has_website = kwargs.get('has_website')
            if has_website is not None:
                if has_website.lower() == 'true':
                    domain.append(('website', '!=', False))
                else:
                    domain.append(('website', '=', False))

            country = kwargs.get('country')
            if country:
                domain.append(('country_id.name', 'ilike', country))

            state = kwargs.get('state')
            if state:
                domain.append(('state_id.name', 'ilike', state))

            tag_id = kwargs.get('tag_id')
            if tag_id and tag_id.isdigit():
                domain.append(('category_id', 'in', int(tag_id)))

            tag_name = kwargs.get('tag')
            if tag_name:
                domain.append(('category_id.name', 'ilike', tag_name))

            search = kwargs.get('search')
            if search:
                domain += ['|', '|', '|',
                           ('name', 'ilike', search),
                           ('email', 'ilike', search),
                           ('phone', 'ilike', search),
                           ('website', 'ilike', search)]

            try:
                limit = int(kwargs.get('limit', 80))
            except Exception:
                limit = 80
            try:
                offset = int(kwargs.get('offset', 0))
            except Exception:
                offset = 0

            partners = Partner.search(domain, limit=limit, offset=offset, order='name asc')

            result = []
            for p in partners:
                title_name = p.title.name if p.title else ''
                job_title  = p.function or ''
                state_name = p.state_id.name if p.state_id else ''
                country_name = p.country_id.name if p.country_id else ''
                street = ' '.join([x for x in [p.street, p.street2] if x]) or ''
                address = ', '.join([x for x in [street, p.city or '', state_name, country_name] if x]) or ''

                tags = _tags_of_partner(p)
                result.append({
                    'id': p.id,
                    'name': p.name or '',
                    'image': f'/web/image/res.partner/{p.id}/image_512',
                    'website': p.website or '',
                    'phone': p.phone or '',
                    'mobile': p.mobile or '',
                    'email': p.email or '',
                    'title': title_name,        # Mr/Ms… من res.partner.title
                    'job_title': job_title,     # function
                    'state': state_name,
                    'state_id': p.state_id.id if p.state_id else False,
                    'city': p.city or '',
                    'country': country_name,
                    'address': address,
                    'tags': tags,
                    'tag_ids': [t['id'] for t in tags],
                })

            return request.make_response(
                json.dumps(result, ensure_ascii=False),
                headers=[('Content-Type', 'application/json; charset=utf-8')]
            )
        except Exception as e:
            _logger.exception('Error in /odoo/public/contacts: %s', e)
            return request.make_response(
                json.dumps({'error': 'internal_error', 'details': str(e)}),
                headers=[('Content-Type', 'application/json')],
                status=500
            )
